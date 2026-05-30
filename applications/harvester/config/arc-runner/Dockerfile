FROM summerwind/actions-runner-dind:latest

USER root

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y \
        libnss3 \
        libnspr4 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libdrm2 \
        libxkbcommon0 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxrandr2 \
        libgbm1 \
        libpango-1.0-0 \
        libcairo2 \
        libasound2 \
        libatspi2.0-0 \
        libwayland-client0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN DOCKER_COMPOSE_VERSION="2.36.1" \
    && mkdir -p /usr/local/lib/docker/cli-plugins \
    && curl -fsSL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
        -o /usr/local/lib/docker/cli-plugins/docker-compose \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

RUN LLAMA_VERSION="b9354" \
    && curl -fSL -o /tmp/llama-cpp.tar.gz \
        https://github.com/ggml-org/llama.cpp/releases/download/${LLAMA_VERSION}/llama-${LLAMA_VERSION}-bin-ubuntu-x64.tar.gz \
    && mkdir -p /opt/llama.cpp \
    && tar -xzf /tmp/llama-cpp.tar.gz -C /opt/llama.cpp \
    && ln -sf /opt/llama.cpp/llama-${LLAMA_VERSION}/llama-server /usr/local/bin/llama-server \
    && rm -f /tmp/llama-cpp.tar.gz

USER runner
