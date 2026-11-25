#!/bin/bash
# Build & push the arc-runner image to GHCR (custom ARC runner for the
# infersec CI pools; same image as .github/workflows/build-arc-runner.yml).
set -euo pipefail

if [ $# -gt 1 ]; then
  echo "Usage: $0 [version]  (default: IMAGE_VERSION from the build workflow)" >&2
  exit 64
fi

IMAGE_REF="${IMAGE_REF:-ghcr.io/perry-mitchell/homelab-infra/arc-runner-infersec}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WORKFLOW_FILE="$REPO_ROOT/.github/workflows/build-arc-runner.yml"
VERSION="${1:-$(sed -n 's/^  IMAGE_VERSION: "\(.*\)"$/\1/p' "$WORKFLOW_FILE")}"

echo "Image:    ${IMAGE_REF}:${VERSION}"
echo "Requires: docker login ghcr.io -u perry-mitchell (PAT: write:packages)"
echo

if docker buildx imagetools inspect "${IMAGE_REF}:${VERSION}" >/dev/null 2>&1; then
  echo "Error: ${IMAGE_REF}:${VERSION} already exists — choose a new, unique version." >&2
  exit 1
fi

docker build -t "${IMAGE_REF}:${VERSION}" \
  -f "$REPO_ROOT/applications/harvester/config/arc-runner/Dockerfile" \
  "$REPO_ROOT"

docker push "${IMAGE_REF}:${VERSION}"

DIGEST="$(docker buildx imagetools inspect "${IMAGE_REF}:${VERSION}" --format '{{.Manifest.Digest}}')"

echo
echo "Pushed: ${IMAGE_REF}:${VERSION}  (${DIGEST})"
echo
echo "Ensure this tag matches:"
echo "  applications/harvester/init_versions.tf -> arc_runner.tag"
echo "  .github/workflows/build-arc-runner.yml -> IMAGE_VERSION"
