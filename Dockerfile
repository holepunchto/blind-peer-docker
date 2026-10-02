# syntax=docker/dockerfile:1

# Node.js image for installing dependencies and running the node variant.
ARG NODE_IMAGE=node:24.20.0-slim@sha256:ba849c60be29959425b8734d57b8b4b7d56f98edd9504c9af091d5281095a71e
# Base image for the bare variant.
ARG BASE_IMAGE=debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171
# Version of the bare-runtime-linux-<arch> package.
ARG BARE_VERSION=1.34.1
# Set automatically by buildx (amd64, arm64).
ARG TARGETARCH

# Installer: resolve dependencies from the lockfile for the target architecture.
FROM ${NODE_IMAGE} AS installer

# Inherits from top-level.
ARG TARGETARCH

ENV NODE_ENV=production

WORKDIR /home/blind-peer/

COPY package.json package-lock.json ./

# Install inside the image to ensure bindings use the correct architecture.
# Native addons ship prebuilds for every platform, so drop all but the target.
RUN npm ci --omit=dev \
    && npm cache clean --force \
    && case "${TARGETARCH}" in \
        amd64) prebuild=linux-x64 ;; \
        arm64) prebuild=linux-arm64 ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && find node_modules -type d -path '*/prebuilds/*' -prune ! -name "${prebuild}" \
        -exec rm -rf {} +

# Bare runtime: install the platform binary package directly (not the `bare` wrapper).
FROM ${NODE_IMAGE} AS bare-runtime

# Inherits from top-level.
ARG TARGETARCH
ARG BARE_VERSION

# Installs to $(npm root -g)/bare-runtime-linux-<arch>, linked as /usr/local/bin/bare,
# then check the Bare runtime binary works.
RUN case "${TARGETARCH}" in \
        amd64) platform=linux-x64 ;; \
        arm64) platform=linux-arm64 ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && npm install -g "bare-runtime-${platform}@${BARE_VERSION}" \
    && npm cache clean --force \
    && bare --version

# Node.js variant: docker build --target node .
FROM ${NODE_IMAGE} AS node

ENV NODE_ENV=production

# Tells docker-entrypoint.sh to start blind-peer with Node.js.
ENV BLIND_PEER_RUNTIME=node

# Unprivileged runtime user with a fixed UID/GID for volume permissions.
RUN groupadd -g 21655 blind-peer \
    && useradd \
        -u 21655 \
        -g 21655 \
        --no-log-init \
        --shell /usr/sbin/nologin \
        --create-home \
        blind-peer

# rocksdb-native requires libatomic at runtime.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libatomic1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/blind-peer/

# Keep application dependencies owned by root so the runtime user cannot modify them.
# Skip Bare-only prebuilds (*.bare), Node.js loads the *.node ones.
COPY --from=installer --exclude=**/prebuilds/**/*.bare /home/blind-peer/node_modules ./node_modules

COPY --chmod=0755 docker-entrypoint.sh /home/blind-peer/

USER 21655:21655

# Ensure correct permissions on corestore dir by already creating it
RUN mkdir /home/blind-peer/store
VOLUME /home/blind-peer/store

# Ready once the blind peer is listening on the DHT (checked via the control socket).
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --start-interval=2s \
    CMD ["/home/blind-peer/docker-entrypoint.sh", "readiness-probe"]

ENTRYPOINT ["/home/blind-peer/docker-entrypoint.sh"]

# Bare variant (default, last stage): docker build .
FROM ${BASE_IMAGE} AS bare

ENV NODE_ENV=production

# Tells docker-entrypoint.sh to start blind-peer with Bare.
ENV BLIND_PEER_RUNTIME=bare

# Unprivileged runtime user with a fixed UID/GID for volume permissions.
RUN groupadd -g 21655 blind-peer \
    && useradd \
        -u 21655 \
        -g 21655 \
        --no-log-init \
        --shell /usr/sbin/nologin \
        --create-home \
        blind-peer

# rocksdb-native requires libatomic at runtime.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libatomic1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/blind-peer/

COPY --from=bare-runtime /usr/local/bin/bare /usr/local/bin/bare

# Keep application dependencies owned by root so the runtime user cannot modify them.
# Skip Node.js-only prebuilds (*.node), Bare loads the *.bare ones.
COPY --from=installer --exclude=**/prebuilds/**/*.node /home/blind-peer/node_modules ./node_modules

COPY --chmod=0755 docker-entrypoint.sh /home/blind-peer/

USER 21655:21655

# Ensure correct permissions on corestore dir by already creating it
RUN mkdir /home/blind-peer/store
VOLUME /home/blind-peer/store

# Ready once the blind peer is listening on the DHT (checked via the control socket).
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --start-interval=2s \
    CMD ["/home/blind-peer/docker-entrypoint.sh", "readiness-probe"]

ENTRYPOINT ["/home/blind-peer/docker-entrypoint.sh"]
