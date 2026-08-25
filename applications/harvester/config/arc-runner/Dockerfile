# Custom ARC runner image for infersec E2E jobs.
# Base is the official runner image used by gha-runner-scale-set with
# containerMode=dind (the Docker daemon runs as a sidecar; this image only
# needs the docker CLI + compose plugin to talk to it).
# NOTE: keep the base image within 30 days of the latest actions/runner
# release - GitHub silently stops queueing jobs to deprecated runner
# versions (jobs queue forever, nothing errors). See
# actions/actions-runner-controller#4601.
FROM ghcr.io/actions/actions-runner:2.336.0

USER root

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Playwright / headless browser dependencies (Ubuntu 24.04 package names)
RUN apt-get update \
    && apt-get install -y \
        libnss3 \
        libnspr4 \
        libatk1.0-0t64 \
        libatk-bridge2.0-0t64 \
        libcups2t64 \
        libdrm2 \
        libxkbcommon0 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxrandr2 \
        libgbm1 \
        libpango-1.0-0 \
        libcairo2 \
        libglib2.0-0t64 \
        libasound2t64 \
        libatspi2.0-0t64 \
        libwayland-client0 \
        libgomp1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Firefox-specific Playwright dependencies (chromium needs none of these;
# names verified against ubuntu:24.04 - libxtst6 has no t64 variant)
RUN apt-get update \
    && apt-get install -y \
        libdbus-glib-1-2 \
        libgtk-3-0t64 \
        libxt6t64 \
        libxtst6 \
        libx11-xcb1 \
        libxcursor1 \
        libgdk-pixbuf-2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI + compose plugin (daemon is provided by the dind sidecar)
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# llama.cpp for inference E2E tests (kept in sync with infersec CI)
RUN LLAMA_VERSION="b9354" \
    && curl -fSL -o /tmp/llama-cpp.tar.gz \
        https://github.com/ggml-org/llama.cpp/releases/download/${LLAMA_VERSION}/llama-${LLAMA_VERSION}-bin-ubuntu-x64.tar.gz \
    && mkdir -p /opt/llama.cpp \
    && tar -xzf /tmp/llama-cpp.tar.gz -C /opt/llama.cpp \
    && ln -sf /opt/llama.cpp/llama-${LLAMA_VERSION}/llama-server /usr/local/bin/llama-server \
    && rm -f /tmp/llama-cpp.tar.gz

USER runner
