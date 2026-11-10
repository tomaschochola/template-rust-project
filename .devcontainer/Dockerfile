# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

ARG TARGETARCH

FROM scratch AS node-amd64

ADD --checksum=sha256:5848553868b402d3fabb5b09270649977780a390f832155721025a08b5104455 \
    https://nodejs.org/dist/v26.13.0/node-v26.13.0-linux-x64.tar.gz \
    /tmp/node.tgz

FROM scratch AS node-arm64

ADD --checksum=sha256:439e9c438acdf6a6ffe47418da709153d66c4bed812e30a473faacb107dd2791 \
    https://nodejs.org/dist/v26.13.0/node-v26.13.0-linux-arm64.tar.gz \
    /tmp/node.tgz

FROM node-${TARGETARCH} AS node

FROM scratch AS rustup-amd64

ADD --chmod=0755 --checksum=sha256:5be191e8c70a5007074254cb74d78dbfdd25cd5a61c27de7b8e5410122ec24f4 \
    https://static.rust-lang.org/rustup/archive/1.29.2/x86_64-unknown-linux-gnu/rustup-init \
    /tmp/rustup-init

FROM scratch AS rustup-arm64

ADD --chmod=0755 --checksum=sha256:a9c168dbea81a84671c6b7a5c1795cb0eb699020110d107ddfca427bd797e697 \
    https://static.rust-lang.org/rustup/archive/1.29.2/aarch64-unknown-linux-gnu/rustup-init \
    /tmp/rustup-init

FROM rustup-${TARGETARCH} AS rustup

FROM docker.io/library/ubuntu:26.04@sha256:19fcd1bf268f02b60aca3bd30bd8a6d9a11759a430e32921833e65f16d87348a

COPY --from=node /tmp/node.tgz /tmp/node.tgz
COPY --from=rustup /tmp/rustup-init /tmp/rustup-init

ENV CARGO_HOME=/usr/local/cargo
ENV RUST_VERSION=1.99.1
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH=/usr/local/cargo/bin:${PATH}

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --no-install-recommends \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends ca-certificates fd-find gcc git libarchive-tools libatomic1 libc6-dev make openssh-client shellcheck sudo \
    && tar --extract --gzip --file /tmp/node.tgz --directory /usr/local --strip-components=1 --no-same-owner --exclude='*/README.md' --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' \
    && ln --symbolic /usr/bin/fdfind /usr/local/bin/fd \
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

RUN npm install --global --prefix=/usr/local --ignore-scripts npm@12.2.1 \
    && rm -rf /root/.npm

RUN /tmp/rustup-init -y --no-modify-path --profile default --default-toolchain "$RUST_VERSION" \
    && rm --force -- /tmp/rustup-init \
    && chmod -R a+w "$RUSTUP_HOME" "$CARGO_HOME" \
    && rustup component add --toolchain "$RUST_VERSION" rust-analyzer rust-src \
    && rustup target add --toolchain "$RUST_VERSION" \
        x86_64-unknown-linux-gnuasan \
        x86_64-unknown-linux-gnumsan \
        x86_64-unknown-linux-gnutsan

ENV CARGO_HOME=/home/ubuntu/.cargo
ENV NPM_CONFIG_PREFIX=/home/ubuntu/.local
ENV PATH=/home/ubuntu/.cargo/bin:/home/ubuntu/.local/bin:${PATH}

USER ubuntu
