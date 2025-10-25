#!/bin/bash

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

SOURCE_KUBECONFIG="$SCRIPT_DIR/../../k3s/kube.config"
TARGET_KUBECONFIG="$SCRIPT_DIR/../kube.config"

SOURCE_NAMESPACE="smart-home"
SOURCE_DEPLOYMENT="homeassistant"
SOURCE_PVC="longhorn-homeassistant-config"

TARGET_NAMESPACE="smart-home"
TARGET_DEPLOYMENT="homeassistant"
TARGET_PVC="torrens-homeassistant-config"

# Port for data transfer
TRANSFER_PORT=8080

# TLS verification settings (set to "true" to skip TLS verification for clusters with cert issues)
SOURCE_INSECURE="false"
TARGET_INSECURE="true"  # Set to true for Harvester cluster

# Helper functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

error() {
    log "ERROR: $*" >&2
    exit 1
}

# Build kubectl command with appropriate flags
kubectl_source() {
    local cmd="kubectl --kubeconfig=$SOURCE_KUBECONFIG"
    if [ "$SOURCE_INSECURE" = "true" ]; then
        cmd="$cmd --insecure-skip-tls-verify"
    fi
    $cmd "$@"
}

kubectl_target() {
    local cmd="kubectl --kubeconfig=$TARGET_KUBECONFIG"
    if [ "$TARGET_INSECURE" = "true" ]; then
        cmd="$cmd --insecure-skip-tls-verify"
    fi
    $cmd "$@"
}

cleanup() {
    log "Cleaning up..."

    # Delete source pod
    if [ -n "$SOURCE_POD_CREATED" ]; then
        log "Deleting source pod..."
        kubectl_source -n "$SOURCE_NAMESPACE" delete pod volume-migration-source --ignore-not-found=true --wait=false
    fi

    # Delete target pod
    if [ -n "$TARGET_POD_CREATED" ]; then
        log "Deleting target pod..."
        kubectl_target -n "$TARGET_NAMESPACE" delete pod volume-migration-target --ignore-not-found=true --wait=false
    fi

    # Kill port-forward if running
    if [ -n "$PORT_FORWARD_PID" ]; then
        log "Killing port-forward process..."
        kill "$PORT_FORWARD_PID" 2>/dev/null || true
    fi
}

trap cleanup EXIT

# Step 1: Scale down source deployment
log "Scaling down source deployment to 0 replicas..."
kubectl_source -n "$SOURCE_NAMESPACE" scale deployment "$SOURCE_DEPLOYMENT" --replicas=0
kubectl_source -n "$SOURCE_NAMESPACE" wait --for=delete pod -l app="$SOURCE_DEPLOYMENT" --timeout=300s || true

# Step 2: Scale down target deployment
log "Scaling down target deployment to 0 replicas..."
kubectl_target -n "$TARGET_NAMESPACE" scale deployment "$TARGET_DEPLOYMENT" --replicas=0
kubectl_target -n "$TARGET_NAMESPACE" wait --for=delete pod -l app="$TARGET_DEPLOYMENT" --timeout=300s || true

# Step 3: Create source pod with volume mounted
log "Creating source pod..."
kubectl_source -n "$SOURCE_NAMESPACE" apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: volume-migration-source
  labels:
    app: volume-migration
spec:
  containers:
  - name: data-source
    image: alpine:latest
    command: ["/bin/sh"]
    args:
      - -c
      - |
        apk add --no-cache socat tar
        while true; do
          socat TCP-LISTEN:${TRANSFER_PORT},reuseaddr,fork SYSTEM:'tar czf - -C /data .',stderr
        done
    volumeMounts:
    - name: data
      mountPath: /data
    ports:
    - containerPort: ${TRANSFER_PORT}
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: ${SOURCE_PVC}
  restartPolicy: Never
EOF

SOURCE_POD_CREATED=1

log "Waiting for source pod to be ready..."
kubectl_source -n "$SOURCE_NAMESPACE" wait --for=condition=ready pod/volume-migration-source --timeout=300s

# Step 4: Create target pod with volume mounted
log "Creating target pod..."
kubectl_target -n "$TARGET_NAMESPACE" apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: volume-migration-target
  labels:
    app: volume-migration
spec:
  containers:
  - name: data-target
    image: alpine:latest
    command: ["/bin/sh"]
    args:
      - -c
      - |
        apk add --no-cache socat tar
        echo "Waiting for incoming data..."
        socat TCP-LISTEN:${TRANSFER_PORT},reuseaddr SYSTEM:'rm -rf /data/* /data/..?* /data/.[!.]* 2>/dev/null || true; tar xzf - -C /data',stderr
        echo "Data received and extracted"
        sleep 3600
    volumeMounts:
    - name: data
      mountPath: /data
    ports:
    - containerPort: ${TRANSFER_PORT}
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: ${TARGET_PVC}
  restartPolicy: Never
EOF

TARGET_POD_CREATED=1

log "Waiting for target pod to be ready..."
kubectl_target -n "$TARGET_NAMESPACE" wait --for=condition=ready pod/volume-migration-target --timeout=300s

# Give containers time to start their listeners
sleep 5

# Step 5: Copy data using port-forward
log "Setting up port-forward to source pod..."
kubectl_source -n "$SOURCE_NAMESPACE" port-forward volume-migration-source ${TRANSFER_PORT}:${TRANSFER_PORT} &
PORT_FORWARD_PID=$!

# Wait for port-forward to be ready
sleep 3

log "Starting data transfer from source to target..."
log "Connecting to source via localhost:${TRANSFER_PORT}..."

# Stream data from source through local machine to target
if nc -z localhost ${TRANSFER_PORT} 2>/dev/null; then
    kubectl_target -n "$TARGET_NAMESPACE" exec volume-migration-target -- sh -c "nc localhost ${TRANSFER_PORT}" < <(nc localhost ${TRANSFER_PORT}) || \
    kubectl_target -n "$TARGET_NAMESPACE" exec -i volume-migration-target -- sh -c "
        apk add --no-cache curl >/dev/null 2>&1
        rm -rf /data/* /data/..?* /data/.[!.]* 2>/dev/null || true
        curl -s http://host.docker.internal:${TRANSFER_PORT} | tar xzf - -C /data
    " || \
    (
        log "Using kubectl cp method as fallback..."

        # Create temporary directory
        TEMP_DIR=$(mktemp -d)
        trap "rm -rf $TEMP_DIR" EXIT

        log "Copying data from source pod to local temporary directory..."
        kubectl_source -n "$SOURCE_NAMESPACE" exec volume-migration-source -- tar czf - -C /data . > "$TEMP_DIR/data.tar.gz"

        log "Emptying target volume..."
        kubectl_target -n "$TARGET_NAMESPACE" exec volume-migration-target -- sh -c "rm -rf /data/* /data/..?* /data/.[!.]* 2>/dev/null || true"

        log "Copying data from local to target pod..."
        kubectl_target -n "$TARGET_NAMESPACE" exec -i volume-migration-target -- tar xzf - -C /data < "$TEMP_DIR/data.tar.gz"

        log "Data transfer complete!"
    )
else
    error "Could not connect to source pod port-forward"
fi

log "Data migration completed successfully!"

# Step 6 is handled by cleanup function

# Step 7: Keep source deployment at 0 (already done, no action needed)
log "Source deployment remains at 0 replicas"

# # Step 8: Scale up target deployment
# log "Scaling target deployment to 1 replica..."
# kubectl_target -n "$TARGET_NAMESPACE" scale deployment "$TARGET_DEPLOYMENT" --replicas=1

log "Waiting for target deployment to be ready..."
kubectl_target -n "$TARGET_NAMESPACE" wait --for=condition=available deployment/"$TARGET_DEPLOYMENT" --timeout=300s

log "Migration complete! Target deployment is now running with migrated data."
log "Source deployment remains scaled to 0."
