#!/bin/bash
# Build & push an amd64 torium image to GHCR (upstream is arm64-only).
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <version>  (e.g. 1.0.0)" >&2
  exit 64
fi

VERSION="$1"
IMAGE_REF="${IMAGE_REF:-ghcr.io/perry-mitchell/homelab-infra/torium}"
TORIUM_REF="${TORIUM_REF:-ee25b53aea9d73664682c4cefbc738a43024dc3c}"

echo "Image:    ${IMAGE_REF}:${VERSION}"
echo "Source:   ahnl/torium @ ${TORIUM_REF}"
echo "Requires: docker login ghcr.io -u perry-mitchell (PAT: write:packages)"
echo

if docker buildx imagetools inspect "${IMAGE_REF}:${VERSION}" >/dev/null 2>&1; then
  echo "Error: ${IMAGE_REF}:${VERSION} already exists — choose a new, unique version." >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone -q https://github.com/ahnl/torium "$TMP/torium"
git -C "$TMP/torium" checkout -q "$TORIUM_REF"

docker build -t "${IMAGE_REF}:${VERSION}" "$TMP/torium"
docker push "${IMAGE_REF}:${VERSION}"

DIGEST="$(docker buildx imagetools inspect "${IMAGE_REF}:${VERSION}" --format '{{.Manifest.Digest}}')"

echo
echo "Pushed: ${IMAGE_REF}:${VERSION}  (${DIGEST})"
echo
echo "Set in applications/harvester/init_versions.tf -> torium_mcp:"
echo "  uri = \"${IMAGE_REF}\""
echo "  tag = \"${VERSION}@${DIGEST}\""
