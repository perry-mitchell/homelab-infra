#!/bin/bash

set +e  # Don't exit on error
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "Shutting down the k3s cluster..."
# sleep 5

# nodes=$(kubectl get nodes -o custom-columns=NAME:.metadata.name --no-headers)

# for node in $nodes; do
#     echo "Draining node: ${node}"
#     kubectl drain "$node" --ignore-daemonsets --delete-emptydir-data
# done

# nodes_data=$(hcl2json "$SCRIPT_DIR/../terraform.tfvars" | jq -r '
#   [.nodes[] | {
#     ip: .ip,
#     user: .user,
#     password: .password
#   }] | to_entries[] | "\(.value.ip)|\(.value.user)|\(.value.password)"
# ')
nodes_data=$(hcl2json "$SCRIPT_DIR/../terraform.tfvars" | jq -r '
  .nodes[] | "\(.ip)|\(.user)|\(.password)"
')

echo "$nodes_data" | while IFS='|' read -r ip user password; do
    echo "Shutting down node: $ip (user: $user)"

    SSHPASS="$password" sshpass -v -e ssh -v -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$user@$ip" << EOL
        shutdown -hP now
EOL
    ssh_status=$?
    echo "SSH exit status: $ssh_status"

    echo "Successfully stopped node: ${ip}"
    echo "Moving to next node..."
    sleep 1

    echo "Successfully stopped node: ${ip}"
done
