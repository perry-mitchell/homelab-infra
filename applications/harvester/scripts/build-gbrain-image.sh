#!/bin/bash
# Build & push the gbrain image to GHCR (upstream garrytan/gbrain ships no
# container image; bun installs the CLI from the pinned upstream release tag).
set -euo pipefail

if [ $# -gt 1 ]; then
  echo "Usage: $0 [version]  (default: the pinned GBRAIN_REF)" >&2
  exit 64
fi

IMAGE_REF="${IMAGE_REF:-ghcr.io/perry-mitchell/homelab-infra/gbrain}"
GBRAIN_REF="${GBRAIN_REF:-v0.60.176.0}"
VERSION="${1:-$GBRAIN_REF}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="$SCRIPT_DIR/../config/gbrain/Dockerfile"

echo "Image:    ${IMAGE_REF}:${VERSION}"
echo "Source:   garrytan/gbrain @ ${GBRAIN_REF}"
echo "Requires: docker login ghcr.io -u perry-mitchell (PAT: write:packages)"
echo

if docker buildx imagetools inspect "${IMAGE_REF}:${VERSION}" >/dev/null 2>&1; then
  echo "Error: ${IMAGE_REF}:${VERSION} already exists — choose a new, unique version." >&2
  exit 1
fi

docker build \
  -f "$DOCKERFILE" \
  --build-arg "GBRAIN_REF=${GBRAIN_REF}" \
  -t "${IMAGE_REF}:${VERSION}" \
  "$(dirname "$DOCKERFILE")"

docker push "${IMAGE_REF}:${VERSION}"

DIGEST="$(docker buildx imagetools inspect "${IMAGE_REF}:${VERSION}" --format '{{.Manifest.Digest}}')"

echo
echo "Pushed: ${IMAGE_REF}:${VERSION}  (${DIGEST})"
echo
echo "Set in applications/harvester/init_versions.tf -> gbrain:"
echo "  uri = \"${IMAGE_REF}\""
echo "  tag = \"${VERSION}@${DIGEST}\""
