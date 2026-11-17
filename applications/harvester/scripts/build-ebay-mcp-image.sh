#!/bin/bash
# Build & push the ebay-mcp image to GHCR (upstream YosefHayim/ebay-mcp ships
# no container image; npm installs the CLI from the pinned npm release).
set -euo pipefail

if [ $# -gt 1 ]; then
  echo "Usage: $0 [version]  (default: the pinned EBAY_MCP_REF)" >&2
  exit 64
fi

IMAGE_REF="${IMAGE_REF:-ghcr.io/perry-mitchell/homelab-infra/ebay-mcp}"
EBAY_MCP_REF="${EBAY_MCP_REF:-2.0.11}"
VERSION="${1:-$EBAY_MCP_REF}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="$SCRIPT_DIR/../config/ebay-mcp/Dockerfile"

echo "Image:    ${IMAGE_REF}:${VERSION}"
echo "Source:   npm ebay-mcp @ ${EBAY_MCP_REF}"
echo "Requires: docker login ghcr.io -u perry-mitchell (PAT: write:packages)"
echo

if docker buildx imagetools inspect "${IMAGE_REF}:${VERSION}" >/dev/null 2>&1; then
  echo "Error: ${IMAGE_REF}:${VERSION} already exists — choose a new, unique version." >&2
  exit 1
fi

docker build \
  -f "$DOCKERFILE" \
  --build-arg "EBAY_MCP_REF=${EBAY_MCP_REF}" \
  -t "${IMAGE_REF}:${VERSION}" \
  "$(dirname "$DOCKERFILE")"

docker push "${IMAGE_REF}:${VERSION}"

DIGEST="$(docker buildx imagetools inspect "${IMAGE_REF}:${VERSION}" --format '{{.Manifest.Digest}}')"

echo
echo "Pushed: ${IMAGE_REF}:${VERSION}  (${DIGEST})"
echo
echo "Set in applications/harvester/init_versions.tf -> ebay_mcp:"
echo "  uri = \"${IMAGE_REF}\""
echo "  tag = \"${VERSION}@${DIGEST}\""
