# HERDR_DOCKER_K8S — docker compose on the Harvester cluster from the herdr VM

Status: planned, not implemented.

## Objective

When `docker compose` commands run inside the herdr VM, workloads are
deployed onto the Harvester/Kubernetes cluster the VM sits in — with real
compose syntax and real `build:` support — instead of running containers
inside the VM.

## Decisions (locked)

| Topic | Decision |
| --- | --- |
| Image registry | In-cluster registry (not GHCR) |
| Namespace | `docker-development` — hosts the registry and ALL compose-deployed workloads |
| Shim scope | `up`, `down`, `stop`, `build`, `push`, `ps`, `logs` only |
| `docker run` | NOT mapped — out of scope |
| Builds | Real Docker daemon + BuildKit inside the herdr VM |

## Architecture

```
herdr VM                                             Harvester cluster
─────────────────────────────────────────────        ─────────────────
docker CLI (real)
 └─ docker-compose shim (CLI plugin, user path shadows system plugin)
     ├─ up:    real build (in-VM daemon) ───────────► push ──► registry (NodePort)
     │         kompose convert + apply ─────────────────────► workloads in docker-development
     ├─ down:  kompose down
     ├─ stop:  kubectl scale --all --replicas=0
     ├─ build / push: passthrough to the REAL compose plugin (local daemon)
     └─ ps / logs: kubectl get pods / kubectl logs (kompose service labels)
kubeconfig (scoped ServiceAccount, default ns = docker-development)
```

Literal `docker compose` with real `build:` requires a real Docker daemon
(only dockerd/BuildKit executes builds; no k8s operator builds from compose
files). Therefore: build in the VM, push to the in-cluster registry, deploy
via kompose.

## Phases

### Phase 0 — Reachability spike (primary risk)

- Pushing from the VM is trivial (NodePort endpoint + `insecure-registries`
  in VM `daemon.json`).
- **Pulling on the nodes is the risk**: a plain-HTTP or self-signed registry
  requires containerd `registries.yaml` on all three nodes. Harvester is
  RKE2-based: `/etc/rancher/rke2/registries.yaml`, applied rolling with an
  `rke2-server` restart per node (VMs keep running; each node NotReady ~1 min).
- First action: check whether this Harvester version exposes a native
  registry-mirrors setting — `kubectl get settings.harvesterhci.io` — that
  avoids manual node edits. Outcome decides the shape of Phase 2.

### Phase 1 — Cluster side (tofu, new `applications/harvester/app_docker_development.tf`)

- Namespace `docker-development`.
- Registry: `registry:3` image, tag pinned in `init_versions.tf`
  (verify with `scripts/check-image-versions.mjs`), 1 replica,
  Longhorn-backed PVC (start at 50Gi).
- Services: ClusterIP (pull path, cluster DNS) + NodePort (push path,
  stable endpoint on a fixed node IP, e.g. `torrens:30500`).
- RBAC: ServiceAccount `herdr-composer`; Role in `docker-development` with
  CRUD on pods, deployments, statefulsets, services, ingresses, configmaps,
  secrets, PVCs, jobs/cronjobs, plus read on `pods/log`; RoleBinding;
  service-account token secret.
- Deferred: registry garbage-collect CronJob (needs RWX volume or
  scale-to-zero orchestration — add later if space becomes an issue).

### Phase 2 — Node pull path

Per Phase 0 outcome, one of:

1. Harvester-native registry setting (preferred, no node access), or
2. Rolling `registries.yaml` edit + `rke2-server` restart on
   torrens / torrens3 / torrens4 — one node at a time.

### Phase 3 — VM side (SSH to herdr VM; no tofu)

- Install Docker CE (daemon + CLI) and the official compose plugin at the
  system plugin path.
- Install kompose (pinned release).
- Shim at `~/.docker/cli-plugins/docker-compose` — the user plugin path
  shadows the system plugin, so `docker compose …` hits the shim, which
  forwards `build`/`push` to the real plugin binary by absolute path.

  | `docker compose …` | Shim behavior |
  | --- | --- |
  | `up [-d] [--build]` | `kompose up`; with `--build`, real build + push first |
  | `down` | `kompose down` |
  | `stop` | `kubectl scale --all --replicas=0 -n docker-development` (closest k8s analog) |
  | `build` | passthrough to real plugin (in-VM daemon) |
  | `push` | passthrough to real plugin |
  | `ps` | `kubectl get pods` mapped to compose service names |
  | `logs <svc>` | `kubectl logs` via kompose service labels |

- VM `/etc/docker/daemon.json`: `insecure-registries: ["<nodeport-endpoint>"]`.
- Kubeconfig into the VM: token auth against the cluster API server,
  context default namespace = `docker-development`. Never the admin
  `kube.config`.

### Phase 4 — End-to-end validation

Sample compose project with a `build:` service:

1. `docker compose up -d --build` → verify in-VM build, image present in
   registry, pod Running in `docker-development`.
2. `docker compose ps` → maps to the deployed pods.
3. `docker compose logs <svc>` → streams pod logs.
4. `docker compose stop` → workloads scale to zero.
5. `docker compose down` → workloads + PVCs removed.

## Known limitations (accepted)

- `depends_on:` conditions, compose networks, host networking: approximated
  or ignored by kompose.
- Volumes become Longhorn PVCs via the default storage class.
- `docker run` / `docker exec` remain in-VM only.

## Convention for compose files (must be documented for agents)

Any service with `build:` must also declare
`image: <nodeport-endpoint>/<name>:<tag>` so built images land where nodes
pull them. The shim may auto-prefix image names in a later revision.

## Open questions

1. Registry auth: none (LAN-internal, simplest) vs htpasswd basic auth?
2. Approval for worst-case rolling RKE2 restarts on the three nodes?
3. NodePort endpoint format (`torrens:30500`) vs a LoadBalancer IP from the
   Harvester pool?

## Relevant existing assets

- `modules-harvester/service` — deployment/PVC/service pattern for the registry.
- `scripts/check-image-versions.mjs` — pin verification for the registry image.
- herdr VM: joined to tailnet, SSH via `herdr` user, docker not yet installed.
