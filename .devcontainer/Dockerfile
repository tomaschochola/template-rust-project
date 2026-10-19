# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

ARG TARGETARCH

FROM scratch AS node-amd64

ADD --checksum=sha256:28ea0a438de9a13bd7891fd758eee6c7819ee8af5442dfd8d45bd65e56d4228c \
    https://nodejs.org/dist/v24.22.0/node-v24.22.0-linux-x64.tar.gz \
    /tmp/node.tgz

FROM scratch AS node-arm64

ADD --checksum=sha256:b7e7991d5407815adfa74a2a9cd4db683552c8ce32ff4a295c22e972849c3f5d \
    https://nodejs.org/dist/v24.22.0/node-v24.22.0-linux-arm64.tar.gz \
    /tmp/node.tgz

FROM node-${TARGETARCH} AS node

FROM scratch AS rustup-amd64

ADD --checksum=sha256:dda7234360b7f578ca8b0ddcb80145646fa61a67c1720a5abc7051b35c9fcb71 \
    https://static.rust-lang.org/rustup/archive/1.29.1/x86_64-unknown-linux-gnu/rustup-init \
    /tmp/rustup-init

FROM scratch AS rustup-arm64

ADD --checksum=sha256:15f6e4ce9f583b929c996c91562bad6d4454f3281de858b02cdfdef615fac433 \
    https://static.rust-lang.org/rustup/archive/1.29.1/aarch64-unknown-linux-gnu/rustup-init \
    /tmp/rustup-init

FROM rustup-${TARGETARCH} AS rustup

FROM docker.io/library/ubuntu:26.04@sha256:c098726dd9b9733f3e885f8de0ef375206a311b0a317eadc40d347b1115fb944

COPY --from=node /tmp/node.tgz /tmp/node.tgz
COPY --from=rustup /tmp/rustup-init /tmp/rustup-init

ENV RUST_VERSION=1.99.1
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:${PATH}

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --no-install-recommends \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends ca-certificates gcc git libc6-dev make openssh-client sudo \
    && chmod +x /tmp/rustup-init \
    && /tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain "$RUST_VERSION" \
    && rm --force -- /tmp/rustup-init \
    && chmod -R a+w "$RUSTUP_HOME" "$CARGO_HOME" \
    && rustup component add --toolchain "$RUST_VERSION" clippy rust-analyzer rust-src rustfmt \
    && rustup target add --toolchain "$RUST_VERSION" \
        x86_64-unknown-linux-gnuasan \
        x86_64-unknown-linux-gnumsan \
        x86_64-unknown-linux-gnutsan \
    && tar --extract --gzip --file /tmp/node.tgz --directory /usr/local --strip-components=1 --no-same-owner --exclude='*/README.md' --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' \
    && ln --symbolic /usr/local/bin/node /usr/local/bin/nodejs \
    && rm --force -- /tmp/node.tgz \
    && usermod --shell /bin/bash ubuntu \
    && install --directory --owner ubuntu --group ubuntu \
        /home/ubuntu/.cargo \
        /home/ubuntu/.local \
        /home/ubuntu/.local/bin \
        /home/ubuntu/.local/lib \
        /home/ubuntu/.local/lib/node_modules \
    && printf '%s\n' 'ubuntu ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu \
    && rm -rf /var/lib/apt/lists/*

ENV CARGO_HOME=/home/ubuntu/.cargo
ENV NPM_CONFIG_PREFIX=/home/ubuntu/.local
ENV PATH=/home/ubuntu/.local/bin:${PATH}

USER ubuntu
