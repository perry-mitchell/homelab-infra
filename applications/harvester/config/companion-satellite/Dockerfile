# Upstream companion-satellite ships no current container image (their
# docker-publish workflow was disabled in 2023 and the committed Dockerfile
# targets long-gone usb@1/node-hid@1 internals). This builds the official
# source at a pinned release tag with current tooling: usb@3/node-hid@3 ship
# prebuilt natives, so the old udev-patching is unnecessary.
FROM node:24-bookworm AS build
WORKDIR /app

RUN apt-get update && apt-get install -yq --no-install-recommends \
        build-essential python3 zip unzip \
        libusb-1.0-0-dev libudev-dev \
    && rm -rf /var/lib/apt/lists/*

COPY . /app/

RUN corepack enable \
    && YARN_HTTP_TIMEOUT=300000 yarn --immutable \
    && yarn build \
    && yarn tsx -e 'import("./tools/build_thread.mts").then((m) => m.buildSurfaceThreadEntrypoint())'

# Surface plugins run as subprocesses under their own pinned node runtimes;
# fetch the versions declared in assets/nodejs-versions.json (same as pi-image)
RUN node -e "\
const fs = require('fs');\
const { execSync } = require('child_process');\
const versions = JSON.parse(fs.readFileSync('assets/nodejs-versions.json', 'utf8'));\
const arch = process.arch === 'arm64' ? 'arm64' : 'x64';\
for (const [name, v] of Object.entries(versions)) {\
  execSync('mkdir -p node-runtimes/' + name);\
  execSync('curl -fsSL https://nodejs.org/dist/v' + v + '/node-v' + v + '-linux-' + arch + '.tar.gz | tar -xz --strip-components=1 -C node-runtimes/' + name, { stdio: 'inherit' });\
  console.log('node-runtimes/' + name + ' <- v' + v);\
}"

FROM node:24-bookworm-slim

RUN apt-get update && apt-get install -yq --no-install-recommends \
        ca-certificates libusb-1.0-0 libudev1 libatomic1 \
        fontconfig fontconfig-config fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/ /app/

USER node
ENTRYPOINT ["node", "/app/satellite/dist/main.js"]
