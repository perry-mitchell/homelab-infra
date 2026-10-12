# gbrain MCP server image — upstream (garrytan/gbrain) ships no container
# image, so bun installs the CLI from a pinned upstream release tag.
# Built & pushed by applications/harvester/scripts/build-gbrain-image.sh;
# the consumed ref is pinned (with digest) in init_versions.tf.
FROM oven/bun:1

# git: gbrain's persistence layer drives git worktrees; tzdata: TZ env;
# ca-certificates: HTTPS to database/embedding provider at runtime.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG GBRAIN_REF
# oven/bun sets BUN_INSTALL=/usr/local, so the bin shim usually lands in
# /usr/local/bin already; only link when bun used a different global bin dir.
RUN bun install -g "github:garrytan/gbrain#${GBRAIN_REF}" \
    && BGBIN="$(bun pm bin -g 2>/dev/null || echo /root/.bun/bin)" \
    && if [ "$BGBIN" != "/usr/local/bin" ] && [ -e "$BGBIN/gbrain" ]; then \
         ln -sf "$BGBIN/gbrain" /usr/local/bin/gbrain; \
       fi \
    && gbrain --version
