# Makefile

SHELL := /usr/bin/env bash

GNUMAKEFLAGS ?=

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

.SHELLFLAGS := -Eeuo pipefail -c

.DELETE_ON_ERROR:
.SUFFIXES:
.NOTPARALLEL:

# Default goal

.DEFAULT_GOAL := never

.PHONY: never
.SILENT: never
never:
	printf '%s\n' 'No default target. Run an explicit target' >&2
	exit 1

# Options

DEVCONTAINER_FILTER := label=devcontainer.local_folder=$(CURDIR)

DESTDIR ?=

override HOST_OS := $(shell uname -s)

PROGRAM := template-rust-project

RUSTFLAGS ?=

RUSTDOCFLAGS ?=

ifeq ($(origin SOURCE_DATE_EPOCH), undefined)
SOURCE_DATE_EPOCH := $(shell git log -1 --format=%ct 2>/dev/null)
else
override SOURCE_DATE_EPOCH := $(value SOURCE_DATE_EPOCH)
endif

ifeq ($(origin VERSION), undefined)
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null)
else
override VERSION := $(value VERSION)
endif

export SOURCE_DATE_EPOCH
export VERSION

RUST_TARGET_LINUX_AMD64 := x86_64-unknown-linux-gnu
RUST_TARGET_LINUX_ARM64 := aarch64-unknown-linux-gnu
RUST_TARGET_DARWIN_AMD64 := x86_64-apple-darwin
RUST_TARGET_DARWIN_ARM64 := aarch64-apple-darwin

BINARY_LINUX_AMD64_V1 := ./target/build/linux-amd64-v1/$(RUST_TARGET_LINUX_AMD64)/release/$(PROGRAM)
BINARY_LINUX_AMD64_V2 := ./target/build/linux-amd64-v2/$(RUST_TARGET_LINUX_AMD64)/release/$(PROGRAM)
BINARY_LINUX_AMD64_V3 := ./target/build/linux-amd64-v3/$(RUST_TARGET_LINUX_AMD64)/release/$(PROGRAM)
BINARY_LINUX_ARM64_V8 := ./target/build/linux-arm64-v8.0/$(RUST_TARGET_LINUX_ARM64)/release/$(PROGRAM)
BINARY_DARWIN_AMD64_V1 := ./target/build/darwin-amd64-v1/$(RUST_TARGET_DARWIN_AMD64)/release/$(PROGRAM)
BINARY_DARWIN_AMD64_V2 := ./target/build/darwin-amd64-v2/$(RUST_TARGET_DARWIN_AMD64)/release/$(PROGRAM)
BINARY_DARWIN_AMD64_V3 := ./target/build/darwin-amd64-v3/$(RUST_TARGET_DARWIN_AMD64)/release/$(PROGRAM)
BINARY_DARWIN_ARM64_V8 := ./target/build/darwin-arm64-v8.0/$(RUST_TARGET_DARWIN_ARM64)/release/$(PROGRAM)
BINARY_DARWIN_ARM64_M1 := ./target/build/darwin-arm64-m1/$(RUST_TARGET_DARWIN_ARM64)/release/$(PROGRAM)
BINARY_DARWIN_ARM64_M2 := ./target/build/darwin-arm64-m2/$(RUST_TARGET_DARWIN_ARM64)/release/$(PROGRAM)
BINARY_DARWIN_ARM64_M3 := ./target/build/darwin-arm64-m3/$(RUST_TARGET_DARWIN_ARM64)/release/$(PROGRAM)
BINARY_DARWIN_ARM64_M4 := ./target/build/darwin-arm64-m4/$(RUST_TARGET_DARWIN_ARM64)/release/$(PROGRAM)
BINARY_DARWIN_ARM64_M5 := ./target/build/darwin-arm64-m5/$(RUST_TARGET_DARWIN_ARM64)/release/$(PROGRAM)
BINARY_NATIVE := ./target/native/release/$(PROGRAM)

PACKAGE_LINUX_AMD64_V1 := $(PROGRAM)-$(VERSION)-linux-amd64-v1
PACKAGE_LINUX_AMD64_V2 := $(PROGRAM)-$(VERSION)-linux-amd64-v2
PACKAGE_LINUX_AMD64_V3 := $(PROGRAM)-$(VERSION)-linux-amd64-v3
PACKAGE_LINUX_ARM64_V8 := $(PROGRAM)-$(VERSION)-linux-arm64-v8.0
PACKAGE_DARWIN_AMD64_V1 := $(PROGRAM)-$(VERSION)-darwin-amd64-v1
PACKAGE_DARWIN_AMD64_V2 := $(PROGRAM)-$(VERSION)-darwin-amd64-v2
PACKAGE_DARWIN_AMD64_V3 := $(PROGRAM)-$(VERSION)-darwin-amd64-v3
PACKAGE_DARWIN_ARM64_V8 := $(PROGRAM)-$(VERSION)-darwin-arm64-v8.0
PACKAGE_DARWIN_ARM64_M1 := $(PROGRAM)-$(VERSION)-darwin-arm64-m1
PACKAGE_DARWIN_ARM64_M2 := $(PROGRAM)-$(VERSION)-darwin-arm64-m2
PACKAGE_DARWIN_ARM64_M3 := $(PROGRAM)-$(VERSION)-darwin-arm64-m3
PACKAGE_DARWIN_ARM64_M4 := $(PROGRAM)-$(VERSION)-darwin-arm64-m4
PACKAGE_DARWIN_ARM64_M5 := $(PROGRAM)-$(VERSION)-darwin-arm64-m5

prefix ?= /usr/local

exec_prefix ?= $(prefix)

bindir ?= $(exec_prefix)/bin

export CARGO_TERM_COLOR := never

# Public goals

.PHONY: fix
fix: cargo_fix clippy_fix rustfmt_fix prettier_fix trimmer_fix

.PHONY: check
check: doctor lint analyze test dist audit

.PHONY: doctor
doctor: git_check npm_config_check npm_doctor rust_toolchain_check

.PHONY: lint
lint: rustfmt_check prettier_check trimmer_check

.PHONY: analyze
analyze: npm_check clippy_check rustdoc_check

.PHONY: test
test: cargo_test cargo_sanitizer_test

.PHONY: audit
audit: npm_audit

.PHONY: update
update: npm_config_check ./package.json ./package-lock.json ./Cargo.toml ./Cargo.lock npm_update cargo_update

.PHONY: clean
clean: cargo_clean

.PHONY: distclean
distclean: clean deps_clean

.PHONY: all
all: cargo_build

.PHONY: installdirs
installdirs:
	install --directory --mode=0755 -- "$(DESTDIR)$(bindir)"

.PHONY: install
install: cargo_build_native installdirs
	install --mode=0755 -- "$(BINARY_NATIVE)" "$(DESTDIR)$(bindir)/$(PROGRAM)"

.PHONY: uninstall
uninstall:
	rm --force -- "$(DESTDIR)$(bindir)/$(PROGRAM)"

.PHONY: installcheck
installcheck:
	test "$$("$(DESTDIR)$(bindir)/$(PROGRAM)" first second)" = "$$(printf 'first\nsecond')"

.PHONY: dist
dist: dist_metadata_check all cargo_dist

.PHONY: postcreate
postcreate: deps_install rust_toolchain_check

.PHONY: up
up: devcontainer_check
	devcontainer up --workspace-folder .

.PHONY: shell
shell: up
	devcontainer exec --workspace-folder . /bin/bash

.PHONY: stop
stop:
	docker container ls --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container stop "$$container"; done

.PHONY: down
down: stop
	docker container ls --all --quiet --filter "$(DEVCONTAINER_FILTER)" | while IFS= read -r container; do docker container rm "$$container"; done

.PHONY: rebuild
rebuild: devcontainer_check down
	devcontainer up --workspace-folder . --build-no-cache

# Protected goals

.PHONY: dist_metadata_check
dist_metadata_check:
	if [[ ! "$${SOURCE_DATE_EPOCH}" =~ ^[0-9]+$$ ]]; then printf '%s\n' 'SOURCE_DATE_EPOCH must contain only decimal digits' >&2; exit 1; fi
	if [[ ! "$${VERSION}" =~ ^[A-Za-z0-9][A-Za-z0-9._+-]*$$ ]]; then printf '%s\n' 'VERSION contains unsupported characters' >&2; exit 1; fi

.PHONY: deps_install
deps_install: npm_install cargo_fetch

.PHONY: deps_clean
deps_clean: npm_clean

.PHONY: trimmer_fix
trimmer_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --no --ignore-scripts -- tooling-trimmer fix .

.PHONY: trimmer_check
trimmer_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --no --ignore-scripts -- tooling-trimmer check .

.PHONY: prettier_fix
prettier_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --no --ignore-scripts -- prettier -w .

.PHONY: prettier_check
prettier_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --no --ignore-scripts -- prettier -c .

.PHONY: npm_config_check
npm_config_check: ./.npmrc
	test "$$(npm config get ignore-scripts)" = "true"
	test "$$(npm config get allow-directory)" = "root"
	test "$$(npm config get allow-file)" = "root"
	test "$$(npm config get allow-git)" = "root"
	test "$$(npm config get allow-remote)" = "root"
	test "$$(npm config get audit)" = "false"
	test "$$(npm config get strict-ssl)" = "true"
	test "$$(npm config get registry)" = "https://registry.npmjs.org/"

.PHONY: npm_doctor
npm_doctor:
	npm doctor connection registry environment permissions cache

.PHONY: npm_check
npm_check: npm_config_check ./node_modules/.package-lock.json
	npm ci --dry-run --ignore-scripts --audit=false --install-links --include=prod --include=dev --include=peer --include=optional
	npm ls --all --install-links --include=prod --include=dev --include=peer --include=optional >/dev/null

.PHONY: npm_audit
npm_audit: npm_config_check ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm audit --ignore-scripts --audit-level=moderate --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_install
npm_install: npm_config_check ./package.json ./package-lock.json
	npm ci --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_update
npm_update: npm_config_check ./package.json ./package-lock.json npm_clean
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_clean
npm_clean:
	rm --force --recursive --one-file-system -- ./node_modules

.PHONY: rust_toolchain_check
rust_toolchain_check: ./rust-toolchain.toml
	test "$$(rustc --version | cut --delimiter=' ' --fields=2)" = "1.98.0"
	test "$$(cargo --version | cut --delimiter=' ' --fields=2)" = "1.98.0"
	test "$$(rustc --verbose --version | sed -n 's/^host: //p')" = "x86_64-unknown-linux-gnu"
	rustup component list --installed | grep -Eq '^clippy-'
	rustup component list --installed | grep -Eq '^rust-analyzer-'
	rustup component list --installed | grep -Eq '^rust-src($$|-)'
	rustup component list --installed | grep -Eq '^rustfmt-'
	rustup target list --installed | grep -Fxq "$(RUST_TARGET_DARWIN_AMD64)"
	rustup target list --installed | grep -Fxq "$(RUST_TARGET_DARWIN_ARM64)"
	rustup target list --installed | grep -Fxq "$(RUST_TARGET_LINUX_AMD64)"
	rustup target list --installed | grep -Fxq "$(RUST_TARGET_LINUX_ARM64)"
	rustup target list --installed | grep -Fxq "x86_64-unknown-linux-gnuasan"
	rustup target list --installed | grep -Fxq "x86_64-unknown-linux-gnumsan"
	rustup target list --installed | grep -Fxq "x86_64-unknown-linux-gnutsan"

.PHONY: cargo_fetch
cargo_fetch: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo fetch --locked

.PHONY: cargo_update
cargo_update: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo update

.PHONY: cargo_fix
cargo_fix: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo fix --locked --all-features --allow-dirty --allow-staged

.PHONY: clippy_fix
clippy_fix: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo clippy --fix --locked --all-features --allow-dirty --allow-staged -- -D warnings

.PHONY: rustfmt_fix
rustfmt_fix: ./Cargo.toml ./rust-toolchain.toml ./rustfmt.toml
	cargo fmt --all

.PHONY: rustfmt_check
rustfmt_check: ./Cargo.toml ./rust-toolchain.toml ./rustfmt.toml
	cargo fmt --all -- --check

.PHONY: clippy_check
clippy_check: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo clippy --locked --all-targets --all-features -- -D warnings

.PHONY: rustdoc_check
rustdoc_check: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	RUSTDOCFLAGS='$(strip $(RUSTDOCFLAGS) -D warnings)' cargo doc --locked --all-features --no-deps --document-private-items

.PHONY: cargo_test
cargo_test: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo test --locked --all-features

.PHONY: cargo_sanitizer_test
cargo_sanitizer_test: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo test --locked --all-features --target x86_64-unknown-linux-gnuasan
	cargo test --locked --all-features --target x86_64-unknown-linux-gnumsan
	cargo test --locked --all-features --target x86_64-unknown-linux-gnutsan

ifeq ($(HOST_OS),Linux)
.PHONY: cargo_build
cargo_build: cargo_build_linux
else ifeq ($(HOST_OS),Darwin)
.PHONY: cargo_build
cargo_build: cargo_build_darwin
else
.PHONY: cargo_build
cargo_build:
	printf '%s\n' 'Unsupported build host: $(HOST_OS)' >&2
	exit 1
endif

.PHONY: cargo_build_linux
cargo_build_linux: cargo_build_linux_amd64_v1 cargo_build_linux_amd64_v2 cargo_build_linux_amd64_v3 cargo_build_linux_arm64_v8

.PHONY: cargo_build_darwin
cargo_build_darwin: cargo_build_darwin_amd64_v1 cargo_build_darwin_amd64_v2 cargo_build_darwin_amd64_v3 cargo_build_darwin_arm64_v8 cargo_build_darwin_arm64_m1 cargo_build_darwin_arm64_m2 cargo_build_darwin_arm64_m3 cargo_build_darwin_arm64_m4 cargo_build_darwin_arm64_m5

.PHONY: cargo_build_linux_amd64_v1
cargo_build_linux_amd64_v1: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/linux-amd64-v1 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=x86-64)' cargo build --locked --release --all-features --target "$(RUST_TARGET_LINUX_AMD64)"

.PHONY: cargo_build_linux_amd64_v2
cargo_build_linux_amd64_v2: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/linux-amd64-v2 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=x86-64-v2)' cargo build --locked --release --all-features --target "$(RUST_TARGET_LINUX_AMD64)"

.PHONY: cargo_build_linux_amd64_v3
cargo_build_linux_amd64_v3: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/linux-amd64-v3 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=x86-64-v3)' cargo build --locked --release --all-features --target "$(RUST_TARGET_LINUX_AMD64)"

.PHONY: cargo_build_linux_arm64_v8
cargo_build_linux_arm64_v8: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/linux-arm64-v8.0 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=generic)' cargo build --locked --release --all-features --target "$(RUST_TARGET_LINUX_ARM64)"

.PHONY: cargo_build_darwin_amd64_v1
cargo_build_darwin_amd64_v1: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/darwin-amd64-v1 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=x86-64)' cargo build --locked --release --all-features --target "$(RUST_TARGET_DARWIN_AMD64)"

.PHONY: cargo_build_darwin_amd64_v2
cargo_build_darwin_amd64_v2: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/darwin-amd64-v2 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=x86-64-v2)' cargo build --locked --release --all-features --target "$(RUST_TARGET_DARWIN_AMD64)"

.PHONY: cargo_build_darwin_amd64_v3
cargo_build_darwin_amd64_v3: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/darwin-amd64-v3 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=x86-64-v3)' cargo build --locked --release --all-features --target "$(RUST_TARGET_DARWIN_AMD64)"

.PHONY: cargo_build_darwin_arm64_v8
cargo_build_darwin_arm64_v8: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/darwin-arm64-v8.0 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=generic)' cargo build --locked --release --all-features --target "$(RUST_TARGET_DARWIN_ARM64)"

.PHONY: cargo_build_darwin_arm64_m1
cargo_build_darwin_arm64_m1: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/darwin-arm64-m1 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=apple-m1)' cargo build --locked --release --all-features --target "$(RUST_TARGET_DARWIN_ARM64)"

.PHONY: cargo_build_darwin_arm64_m2
cargo_build_darwin_arm64_m2: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/darwin-arm64-m2 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=apple-m2)' cargo build --locked --release --all-features --target "$(RUST_TARGET_DARWIN_ARM64)"

.PHONY: cargo_build_darwin_arm64_m3
cargo_build_darwin_arm64_m3: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/darwin-arm64-m3 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=apple-m3)' cargo build --locked --release --all-features --target "$(RUST_TARGET_DARWIN_ARM64)"

.PHONY: cargo_build_darwin_arm64_m4
cargo_build_darwin_arm64_m4: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/darwin-arm64-m4 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=apple-m4)' cargo build --locked --release --all-features --target "$(RUST_TARGET_DARWIN_ARM64)"

.PHONY: cargo_build_darwin_arm64_m5
cargo_build_darwin_arm64_m5: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/build/darwin-arm64-m5 RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=apple-m5)' cargo build --locked --release --all-features --target "$(RUST_TARGET_DARWIN_ARM64)"

.PHONY: cargo_build_native
cargo_build_native: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	CARGO_TARGET_DIR=./target/native cargo build --locked --release --all-features

ifeq ($(HOST_OS),Linux)
.PHONY: cargo_dist
cargo_dist: cargo_dist_linux
else ifeq ($(HOST_OS),Darwin)
.PHONY: cargo_dist
cargo_dist: cargo_dist_darwin
else
.PHONY: cargo_dist
cargo_dist:
	printf '%s\n' 'Unsupported distribution host: $(HOST_OS)' >&2
	exit 1
endif

.PHONY: cargo_dist_linux
cargo_dist_linux: dist_metadata_check cargo_build_linux
	rm --force --recursive --one-file-system -- ./target/package ./dist
	install --directory --mode=0755 -- "./target/package/$(PACKAGE_LINUX_AMD64_V1)" "./target/package/$(PACKAGE_LINUX_AMD64_V1)/bin" "./target/package/$(PACKAGE_LINUX_AMD64_V2)" "./target/package/$(PACKAGE_LINUX_AMD64_V2)/bin" "./target/package/$(PACKAGE_LINUX_AMD64_V3)" "./target/package/$(PACKAGE_LINUX_AMD64_V3)/bin" "./target/package/$(PACKAGE_LINUX_ARM64_V8)" "./target/package/$(PACKAGE_LINUX_ARM64_V8)/bin" ./dist
	install --mode=0755 -- "$(BINARY_LINUX_AMD64_V1)" "./target/package/$(PACKAGE_LINUX_AMD64_V1)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_LINUX_AMD64_V2)" "./target/package/$(PACKAGE_LINUX_AMD64_V2)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_LINUX_AMD64_V3)" "./target/package/$(PACKAGE_LINUX_AMD64_V3)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_LINUX_ARM64_V8)" "./target/package/$(PACKAGE_LINUX_ARM64_V8)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_LINUX_AMD64_V1)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_LINUX_AMD64_V2)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_LINUX_AMD64_V3)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_LINUX_ARM64_V8)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_AMD64_V1).tar.gz" --directory=./target/package -- "$(PACKAGE_LINUX_AMD64_V1)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_AMD64_V2).tar.gz" --directory=./target/package -- "$(PACKAGE_LINUX_AMD64_V2)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_AMD64_V3).tar.gz" --directory=./target/package -- "$(PACKAGE_LINUX_AMD64_V3)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_LINUX_ARM64_V8).tar.gz" --directory=./target/package -- "$(PACKAGE_LINUX_ARM64_V8)"
	cd ./dist && sha256sum -- "$(PACKAGE_LINUX_AMD64_V1).tar.gz" "$(PACKAGE_LINUX_AMD64_V2).tar.gz" "$(PACKAGE_LINUX_AMD64_V3).tar.gz" "$(PACKAGE_LINUX_ARM64_V8).tar.gz" > ./SHA256SUMS

.PHONY: cargo_dist_darwin
cargo_dist_darwin: dist_metadata_check cargo_build_darwin
	rm --force --recursive --one-file-system -- ./target/package ./dist
	install --directory --mode=0755 -- "./target/package/$(PACKAGE_DARWIN_AMD64_V1)" "./target/package/$(PACKAGE_DARWIN_AMD64_V1)/bin" "./target/package/$(PACKAGE_DARWIN_AMD64_V2)" "./target/package/$(PACKAGE_DARWIN_AMD64_V2)/bin" "./target/package/$(PACKAGE_DARWIN_AMD64_V3)" "./target/package/$(PACKAGE_DARWIN_AMD64_V3)/bin" "./target/package/$(PACKAGE_DARWIN_ARM64_V8)" "./target/package/$(PACKAGE_DARWIN_ARM64_V8)/bin" "./target/package/$(PACKAGE_DARWIN_ARM64_M1)" "./target/package/$(PACKAGE_DARWIN_ARM64_M1)/bin" "./target/package/$(PACKAGE_DARWIN_ARM64_M2)" "./target/package/$(PACKAGE_DARWIN_ARM64_M2)/bin" "./target/package/$(PACKAGE_DARWIN_ARM64_M3)" "./target/package/$(PACKAGE_DARWIN_ARM64_M3)/bin" "./target/package/$(PACKAGE_DARWIN_ARM64_M4)" "./target/package/$(PACKAGE_DARWIN_ARM64_M4)/bin" "./target/package/$(PACKAGE_DARWIN_ARM64_M5)" "./target/package/$(PACKAGE_DARWIN_ARM64_M5)/bin" ./dist
	install --mode=0755 -- "$(BINARY_DARWIN_AMD64_V1)" "./target/package/$(PACKAGE_DARWIN_AMD64_V1)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_DARWIN_AMD64_V2)" "./target/package/$(PACKAGE_DARWIN_AMD64_V2)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_DARWIN_AMD64_V3)" "./target/package/$(PACKAGE_DARWIN_AMD64_V3)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_DARWIN_ARM64_V8)" "./target/package/$(PACKAGE_DARWIN_ARM64_V8)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_DARWIN_ARM64_M1)" "./target/package/$(PACKAGE_DARWIN_ARM64_M1)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_DARWIN_ARM64_M2)" "./target/package/$(PACKAGE_DARWIN_ARM64_M2)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_DARWIN_ARM64_M3)" "./target/package/$(PACKAGE_DARWIN_ARM64_M3)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_DARWIN_ARM64_M4)" "./target/package/$(PACKAGE_DARWIN_ARM64_M4)/bin/$(PROGRAM)"
	install --mode=0755 -- "$(BINARY_DARWIN_ARM64_M5)" "./target/package/$(PACKAGE_DARWIN_ARM64_M5)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_DARWIN_AMD64_V1)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_DARWIN_AMD64_V2)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_DARWIN_AMD64_V3)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_DARWIN_ARM64_V8)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_DARWIN_ARM64_M1)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_DARWIN_ARM64_M2)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_DARWIN_ARM64_M3)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_DARWIN_ARM64_M4)/LICENSE"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_DARWIN_ARM64_M5)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_AMD64_V1).tar.gz" --directory=./target/package -- "$(PACKAGE_DARWIN_AMD64_V1)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_AMD64_V2).tar.gz" --directory=./target/package -- "$(PACKAGE_DARWIN_AMD64_V2)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_AMD64_V3).tar.gz" --directory=./target/package -- "$(PACKAGE_DARWIN_AMD64_V3)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_ARM64_V8).tar.gz" --directory=./target/package -- "$(PACKAGE_DARWIN_ARM64_V8)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_ARM64_M1).tar.gz" --directory=./target/package -- "$(PACKAGE_DARWIN_ARM64_M1)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_ARM64_M2).tar.gz" --directory=./target/package -- "$(PACKAGE_DARWIN_ARM64_M2)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_ARM64_M3).tar.gz" --directory=./target/package -- "$(PACKAGE_DARWIN_ARM64_M3)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_ARM64_M4).tar.gz" --directory=./target/package -- "$(PACKAGE_DARWIN_ARM64_M4)"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DARWIN_ARM64_M5).tar.gz" --directory=./target/package -- "$(PACKAGE_DARWIN_ARM64_M5)"
	cd ./dist && sha256sum -- "$(PACKAGE_DARWIN_AMD64_V1).tar.gz" "$(PACKAGE_DARWIN_AMD64_V2).tar.gz" "$(PACKAGE_DARWIN_AMD64_V3).tar.gz" "$(PACKAGE_DARWIN_ARM64_V8).tar.gz" "$(PACKAGE_DARWIN_ARM64_M1).tar.gz" "$(PACKAGE_DARWIN_ARM64_M2).tar.gz" "$(PACKAGE_DARWIN_ARM64_M3).tar.gz" "$(PACKAGE_DARWIN_ARM64_M4).tar.gz" "$(PACKAGE_DARWIN_ARM64_M5).tar.gz" > ./SHA256SUMS

.PHONY: cargo_clean
cargo_clean:
	cargo clean
	rm --force --recursive --one-file-system -- ./dist

.PHONY: git_check
git_check:
	test -z "$$(git ls-files --unmerged)"
	test -z "$$(git ls-files --cached --ignored --exclude-standard)"
	git diff --check
	git diff --cached --check
	git fsck --full --strict --no-dangling --no-progress

.PHONY: devcontainer_check
devcontainer_check:
	devcontainer read-configuration --workspace-folder . >/dev/null
	docker build --check --file ./.devcontainer/Dockerfile ./.devcontainer

# Private targets

./node_modules/.package-lock.json: ./.npmrc ./package.json ./package-lock.json
	$(MAKE) npm_install
