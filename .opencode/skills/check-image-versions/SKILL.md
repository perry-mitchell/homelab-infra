---
name: check-image-versions
description: Use when checking whether pinned container image tags in applications/harvester/init_versions.tf are outdated, comparing current image versions against upstream registries, or deciding which image tags to bump. Triggers on mentions of image versions, outdated containers, tag bumps, or registry tags.
---

# Check container image versions

Run the script from the repo root:

```
node scripts/check-image-versions.mjs
```

Optionally pass a different HCL file as the first argument. Requires Node >= 18, no dependencies.

## What it does

Parses every `uri` + `tag` pair in `init_versions.tf` and queries each image's
registry (Docker Hub, GHCR, lscr.io, quay.io, or any Docker Registry v2 host,
with anonymous token auth and rate-limit retries). Exits `1` when any pinned
image is behind, so it can gate CI.

## Reading the output

| Status | Meaning |
| --- | --- |
| `BEHIND x -> y` | Pinned tag is older than the latest stable; safe bump candidate |
| `ok` | Pinned tag matches the latest stable |
| `floating` | Tag like `latest`/`dev`/`apache` — tracks upstream, nothing to compare |
| `major` | Floating major like `16`, `12`, `pg16` — auto-tracks that major line |
| `digest` | Pinned by `@sha256:` — intentional immutable pin, never bump blindly |
| `not-in-registry` / `error: ...` | Registry lookup problem — investigate, do not assume current |

"Latest" ignores arch/variant suffixes (`-alpine`, `-desktop`, `linux-s390x`),
commit/date-only tags, and pre-releases (rc/beta/alpha).

## When bumping a tag

Edit `applications/harvester/init_versions.tf` only. For database images a
major jump (e.g. postgres 16 -> 18, postgis 16 -> 18) is a data migration, not
a tag flip — flag this to the user instead of bumping. Never run `tofu apply`;
the user runs all tofu write commands themselves.
