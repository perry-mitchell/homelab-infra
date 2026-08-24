# ARC (Actions Runner Controller) — infersec CI

Runs GitHub Actions workflows from `perry-mitchell/infersec` on ephemeral
runners inside the Harvester cluster.

## Layout

| Component | Location |
|---|---|
| ARC controller (`gha-runner-scale-set-controller`) | `arc-system` namespace |
| Runner scale set (`infersec-e2e`) | `infersec-ci` namespace |
| Runner pods (dind, ephemeral) | `infersec-ci` namespace |
| Custom runner image | `ghcr.io/perry-mitchell/homelab-infra/arc-runner-infersec` |

The controller chart creates no GitHub credentials of its own; the scale set
reads the pre-created `arc-github-pat` secret (`github_token` key) in
`infersec-ci`.

## How it works

 * Workflows targeting `runs-on: [self-hosted, e2e-self-hosted]` are picked up
   by the scale set listener (labels are set via `scaleSetLabels`).
 * The scale set spawns ephemeral runner pods (`containerMode: dind`) up to
   `max_runners`. Each pod has its own Docker daemon sidecar, so parallel jobs
   from multiple branches are fully isolated from each other — every branch's
   E2E run gets its own docker engine, network and volumes.
 * Inside a job, the infersec test stack runs via docker compose (unique
   project name + `PORT_*` port blocks per suite, see
   `test-e2e-parallel.sh` in the infersec repo). Everything is destroyed with
   the runner pod when the job finishes.

## Setup / updates

1. Create a fine-grained PAT on `<infersec-repo>` with **Actions: Read
   and write** and **Administration: Read and write** (needed to register
   runners). Put it in `terraform.tfvars` (git ignored):
   ```tfvars
   arc_github_pat = "github_pat_..."
   ```
2. Ensure the runner image exists in GHCR. It is built by the
   `Build ARC Runner Image` workflow — dispatch it manually after merging
   changes to the Dockerfile (workflow_dispatch only works from `main`).
3. Run `tofu plan` / `tofu apply` from `applications/harvester`.

### Image versioning convention

The runner image is referenced from `init_versions.tf`
(`images.arc_runner`). Bump the tag there **and** `IMAGE_VERSION` in the
build workflow whenever the Dockerfile changes, then rebuild.

## Knobs

 * `max_runners` / `min_runners` — autoscaling bounds (defaults: 2 / 0).
 * `runner_cpu_request` / `runner_memory_request` — per runner pod
   (defaults: `4` CPU / `12Gi` — sized for parallel E2E suites with
   llama.cpp). Peak cluster usage ≈ max_runners × requests.
 * `runner_labels` — labels for `runs-on` targeting.

## Troubleshooting

```sh
# Controller logs
kubectl -n arc-system logs deploy/gha-runner-scale-set-controller

# Listener + ephemeral runner pods
kubectl -n infersec-ci get pods
kubectl -n infersec-ci logs <runner-pod> -c runner

# Registered runners / scale set state
kubectl get runnerscalesets -A
kubectl -n infersec-ci get ephemeralrunnersets
```

If jobs queue forever: check the listener pod logs (usually a PAT permission
problem), and confirm the workflow uses both `self-hosted` and
`e2e-self-hosted` labels. If the controller logs show
`failed to get kubernetes secret: "infersec-ci/arc-github-pat"`, the manager
RoleBinding in `infersec-ci` points at the wrong ServiceAccount — the
`controllerServiceAccount.name` value must match the controller chart's
generated SA (`gha-runner-scale-set-controller-gha-rs-controller`).
