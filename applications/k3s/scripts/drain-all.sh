#!/bin/bash

set +e  # Don't exit on error
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Draining all nodes..."

nodes=$(kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers)

for node in $nodes; do
    echo "Draining node: ${node}"
    kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data --timeout="30s" --grace-period="15"
done
