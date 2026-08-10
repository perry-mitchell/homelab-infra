# Joining a New Node to the Harvester Cluster

Reusable steps for adding a management node to an existing Harvester cluster.
Keep values generic — substitute your real VIP, token, hostname, and IP.

## Prerequisites

* A node booted from the Harvester ISO (interactive installer).
* The cluster **VIP** (kube-vip management address — the same IP the dashboard and
  API server are served on) and the **cluster token**.
* The cluster token can be read on any existing node at:
  ```
  /var/lib/rancher/rke2/server/node-token
  ```
* A free static IP on the management network. A node's IP **cannot be changed
  after install** — set it correctly the first time.

## Installer steps

1. **Installation mode** → `Join an existing Harvester cluster`.
2. **Installation role** → `Default Role`.
   The node joins as a **worker** (no `control-plane`/`etcd` roles). Promotion to
   a management node is done **after** join via a topology label — see
   [Promote to management node](#promote-to-management-node) below.
3. **Installation disk** → the node's NVMe.
   **Data disk** → `Use the installation disk`.
4. **Persistent size** → `150G`–`250G`.
   Persistent only stores system packages and container images — don't over-size
   it. The remainder of the disk is given to Longhorn for VM data. (One node here
   ran fine at 150G but sat at ~83% full; ~250G gives safe upgrade headroom.)
5. **HostName** → the new node name.
6. **Network** → static IP (same gateway/DNS/NTP as the other nodes).
7. **VIP Mode** → the cluster management VIP.
8. **Cluster token** → paste the token from an existing node.
9. Confirm and install. The node reboots and joins.

## Verify the join

```
kubectl --kubeconfig=kube.config get nodes
```
The new node shows `Ready` initially as a **worker** (no roles column / just
worker). It is not yet part of etcd.

## Promote to management node

A replacement management node must be promoted after join. **The trigger is the
`topology.kubernetes.io/zone` label** — Harvester promotes a worker to
`control-plane,etcd,master` when it is placed into a zone that completes the
3-zone management topology.

* Check the existing zones first:
  ```
  kubectl --kubeconfig=kube.config get nodes --show-labels | \
    grep -oE 'topology.kubernetes.io/zone=[^ ]*'
  ```
* Label the new node with a **distinct** zone (do not reuse an existing one):
  ```
  kubectl --kubeconfig=kube.config label node <new-node> \
    topology.kubernetes.io/zone=<unused-zone>
  ```
  Harvester then promotes the node. Confirm roles become
  `control-plane,etcd,master` and etcd grows by one member (below).

> Note: the official docs state auto-promotion fires only when a control-plane
> node is *deleted*. In practice on this cluster, adding the distinct zone label
> to a freshly-joined Default node promoted it reliably — that is the
> recommended trigger here. Re-installing with `Management Role` is the
> documented alternative if the label does not promote.

Confirm etcd membership grew by one (read-only):
```
kubectl --kubeconfig=kube.config -n kube-system exec etcd-<existing-node> -- \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/rancher/rke2/server/tls/etcd/server-ca.crt \
  --cert=/var/lib/rancher/rke2/server/tls/etcd/server-client.crt \
  --key=/var/lib/rancher/rke2/server/tls/etcd/server-client.key \
  member list -w table
```
All members should show `started`; no ghost/old members.

## Post-join cleanup

If a previous node died (see `IN_CASE_OF_FAILURE.md`), the `rancher`
(cattle-system) and `harvester` (harvester-system) deployments will have been
scaled **down to 2** replicas to fit a 2-management-node cluster. They use pod
anti-affinity (one replica per management node), so scale them back to 3 **only
after the new node has been promoted to management** (3 control-plane nodes
available):
```
kubectl --kubeconfig=kube.config scale deploy rancher -n cattle-system --replicas=3
kubectl --kubeconfig=kube.config scale deploy harvester -n harvester-system --replicas=3
```
Verify both reach `3/3`:
```
kubectl --kubeconfig=kube.config get deploy -A | grep -E "rancher|harvester"
```

## Notes

* The dead node must be fully gone (no Node object, no Longhorn node, no etcd
  member) before/while joining a replacement. Reusing a dead node's hostname is
  usually safe after cleanup, but prefer a fresh name for audit clarity.
* The new node's disk layout should match the cluster convention: small
  `COS_PERSISTENT` (~150G), the rest as `HARV_LH_DEFAULT` for Longhorn.
