#!/bin/bash
# Build & push the companion-satellite image to GHCR (upstream's image is
# abandoned since 2022; this builds the official source at a pinned tag).
set -euo pipefail

if [ $# -gt 1 ]; then
  echo "Usage: $0 [version]  (default: the pinned SATELLITE_REF)" >&2
  exit 64
fi

IMAGE_REF="${IMAGE_REF:-ghcr.io/perry-mitchell/homelab-infra/companion-satellite}"
SATELLITE_REF="${SATELLITE_REF:-v3.6.0}"
VERSION="${1:-1.0.0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKERFILE="$SCRIPT_DIR/../config/companion-satellite/Dockerfile"
CONTEXT="$(mktemp -d)"

echo "Image:    ${IMAGE_REF}:${VERSION}"
echo "Source:   bitfocus/companion-satellite @ ${SATELLITE_REF}"
echo "Requires: docker login ghcr.io -u perry-mitchell (PAT: write:packages)"
echo

if docker buildx imagetools inspect "${IMAGE_REF}:${VERSION}" >/dev/null 2>&1; then
  echo "Error: ${IMAGE_REF}:${VERSION} already exists — choose a new, unique version." >&2
  exit 1
fi

git clone --depth 1 --branch "$SATELLITE_REF" \
  https://github.com/bitfocus/companion-satellite.git "$CONTEXT/source"
cp "$DOCKERFILE" "$CONTEXT/source/Dockerfile"

docker build -t "${IMAGE_REF}:${VERSION}" "$CONTEXT/source"

docker push "${IMAGE_REF}:${VERSION}"

DIGEST="$(docker buildx imagetools inspect "${IMAGE_REF}:${VERSION}" --format '{{.Manifest.Digest}}')"

echo
echo "Pushed: ${IMAGE_REF}:${VERSION}  (${DIGEST})"
echo
echo "Set in applications/harvester/init_versions.tf -> companion_satellite:"
echo "  uri = \"${IMAGE_REF}\""
echo "  tag = \"${VERSION}@${DIGEST}\""

rm -rf "$CONTEXT"
