#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

KUBECONFIG="$SCRIPT_DIR/../kube.config"

#scp -o StrictHostKeyChecking=no rancher@192.168.202.2:/etc/rancher/rke2/rke2.yaml $KUBECONFIG

ssh -o StrictHostKeyChecking=no rancher@192.168.202.2 'sudo cat /etc/rancher/rke2/rke2.yaml' > $KUBECONFIG

sed -i 's|https://127.0.0.1:6443|https://192.168.202.2:6443|g' $KUBECONFIG

echo "Kubeconfig downloaded to $KUBECONFIG"
