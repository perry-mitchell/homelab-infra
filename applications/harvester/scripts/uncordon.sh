#!/bin/bash

set -eou pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

read -sp "Enter SSH password for rancher user: " SSH_PASSWORD
echo ""

bash $SCRIPT_DIR/download-kube-config.sh $SSH_PASSWORD

# Get node names and their IPs
NODE_DATA=$(kubectl get nodes --output json | jq -r '.items[] | "\(.metadata.name) \(.status.addresses[] | select(.type=="InternalIP") | .address)"')

if [ -z "$NODE_DATA" ]; then
    echo "No nodes found!"
    exit 1
fi

echo "Found nodes:"
echo "$NODE_DATA"
echo ""

NODE_NAMES=()
NODE_IPS=()

while IFS= read -r line; do
  NODE_NAMES+=($(echo "$line" | awk '{print $1}'))
  NODE_IPS+=($(echo "$line" | awk '{print $2}'))
done <<< "$NODE_DATA"

echo "Uncordoning all nodes simultaneously..."

# Cordon all nodes at once in background
for NODE_NAME in "${NODE_NAMES[@]}"; do
  kubectl uncordon "$NODE_NAME" &
done

# Wait for all cordon commands to complete
wait

echo ""
echo "Done! All nodes are now uncordoned."
echo ""

