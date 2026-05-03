# In Case of Failure

## If a node goes down (hardware failure / permanently offline)

### Immediate steps

1. **Delete the node via Harvester UI**: Hosts -> select the dead node -> Delete.
   This orchestrates full cleanup (etcd membership, Longhorn volumes, pod eviction).

2. **Check Longhorn volumes**: If volumes are stuck in "attaching" state after node removal,
   clear the nodeID on each stuck volume:
   ```bash
   kubectl --kubeconfig=kube.config get volumes -n longhorn-system -o json | \
     python3 -c "
   import json, sys
   for v in json.load(sys.stdin)['items']:
       if v['spec'].get('nodeID') == '<DEAD_NODE>':
           print(v['metadata']['name'])
   " | while read vol; do
     kubectl --kubeconfig=kube.config patch volume "$vol" -n longhorn-system \
       --type=json -p='[{"op":"replace","path":"/spec/nodeID","value":""}]'
   done
   ```

3. **Force-delete stuck Terminating pods** (if node removal didn't clear them):
   ```bash
   kubectl --kubeconfig=kube.config delete pods --all-namespaces \
     --field-selector spec.nodeName=<DEAD_NODE>,status.phase!=Running \
     --force --grace-period=0
   ```
   If that doesn't work, strip finalizers:
   ```bash
   kubectl --kubeconfig=kube.config get pods --all-namespaces \
     --field-selector spec.nodeName=<DEAD_NODE> -o json | \
     python3 -c "
   import json, sys
   for p in json.load(sys.stdin)['items']:
       if p['metadata'].get('deletionTimestamp'):
           print(p['metadata']['namespace'], p['metadata']['name'])
   " | while read ns name; do
     kubectl --kubeconfig=kube.config patch pod -n "$ns" "$name" \
       --type=json -p='[{"op":"replace","path":"/metadata/finalizers","value":[]}]'
   done
   ```

4. **Scale down deployments with pod anti-affinity** (rancher, harvester, etc.)
   that request 3 replicas across only 2 healthy nodes:
   ```bash
   kubectl scale deploy rancher -n cattle-system --replicas=2
   kubectl scale deploy harvester -n harvester-system --replicas=2
   ```
   Scale back to 3 when the replacement node joins.

5. **Verify recovery**:
   ```bash
   kubectl get pods -A -o wide | grep -vE 'Running|Completed'
   ```

### Prevention: configure Longhorn for auto-recovery

Set in Longhorn UI -> Settings, or via kubectl:

```
node-down-pod-deletion-policy = delete-when-node-is-down
```

This ensures pods and volumes auto-migrate when a node dies without manual intervention.
