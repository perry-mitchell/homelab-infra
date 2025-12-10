#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SSH_PASSWORD="$1"

KUBECONFIG="$SCRIPT_DIR/../kube.config"

if [ ! -z "$SSH_PASSWORD" ]; then
    sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no rancher@192.168.202.2 'sudo cat /etc/rancher/rke2/rke2.yaml' > $KUBECONFIG
else
    ssh -o StrictHostKeyChecking=no rancher@192.168.202.2 'sudo cat /etc/rancher/rke2/rke2.yaml' > $KUBECONFIG
fi

sed -i 's|https://127.0.0.1:6443|https://192.168.202.2:6443|g' $KUBECONFIG

echo "Kubeconfig downloaded to $KUBECONFIG"
