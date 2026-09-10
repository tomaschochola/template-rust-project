# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32

FROM docker.io/library/node:24-trixie@sha256:f7d34e58713740f9eef9092c0bd6ff10369d132f7238399a4b270f16d47fa608 AS versionednode
FROM docker.io/library/rust:1.98.1-trixie@sha256:462a9af3c54fb4718850d3c602fc0e54452c20b1c12a4e4080fdb001d4b9acbf

COPY --from=versionednode /usr/local/bin/node /usr/local/bin/node
COPY --from=versionednode /usr/local/include/node /usr/local/include/node
COPY --from=versionednode /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=versionednode /usr/local/LICENSE /usr/local/share/doc/node/LICENSE

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade --yes --no-install-recommends \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends gcc-aarch64-linux-gnu git libc6-dev-arm64-cross make openssh-client sudo \
    && rustup component add --toolchain 1.98.1 clippy rust-analyzer rust-src rustfmt \
    && rustup target add --toolchain 1.98.1 \
        aarch64-apple-darwin \
        aarch64-unknown-linux-gnu \
        x86_64-apple-darwin \
        x86_64-unknown-linux-gnu \
        x86_64-unknown-linux-gnuasan \
        x86_64-unknown-linux-gnumsan \
        x86_64-unknown-linux-gnutsan \
    && groupadd --gid 1000 devcontainer \
    && useradd --uid 1000 --gid devcontainer --shell /bin/bash --create-home devcontainer \
    && ln --symbolic ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln --symbolic ../lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && install --directory --owner devcontainer --group devcontainer \
        /home/devcontainer/.cargo \
        /home/devcontainer/.local \
        /home/devcontainer/.local/bin \
        /home/devcontainer/.local/lib \
        /home/devcontainer/.local/lib/node_modules \
    && printf '%s\n' 'devcontainer ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/devcontainer \
    && chmod 0440 /etc/sudoers.d/devcontainer \
    && rm -rf /var/lib/apt/lists/*

ENV CARGO_HOME=/home/devcontainer/.cargo
ENV NPM_CONFIG_PREFIX=/home/devcontainer/.local
ENV PATH=/home/devcontainer/.local/bin:/usr/local/cargo/bin:${PATH}

USER devcontainer
