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

COMPOSE_PROJECT_NAME ?= template-rust-project-$(shell pwd -P | sha256sum | cut -c1-16)
RUSTFLAGS ?=
RUSTDOCFLAGS ?=
DESTDIR ?=
VERSION ?= $(shell v=$$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0); v=$${v#v}; echo "$$v")
SOURCE_DATE_EPOCH ?= $(shell git log -1 --format=%ct 2>/dev/null || echo 0)
prefix ?= /usr/local
exec_prefix ?= $(prefix)
bindir ?= $(exec_prefix)/bin
SUDO ?= sudo

DEVCONTAINER_COMPOSE := ./.devcontainer/docker-compose.yml
DEVCONTAINER_TMPDIR := $(CURDIR)/.devcontainer/.tmp
LC_ALL := C.UTF-8
PROGRAM := template-rust-project
CARGO_TERM_COLOR := never
PACKAGE_DEBUG := $(PROGRAM)-$(VERSION)-debug
PACKAGE_RELEASE := $(PROGRAM)-$(VERSION)-release
PACKAGE_NATIVE := $(PROGRAM)-$(VERSION)-native

export LC_ALL
export VERSION
export SOURCE_DATE_EPOCH
export CARGO_TERM_COLOR
export COMPOSE_PROJECT_NAME

# Public goals

.PHONY: fix
fix: cargo_fix clippy_fix rustfmt_fix prettier_fix trimmer_fix

.PHONY: check
check: devcontainer_gate doctor lint analyze test audit

.PHONY: doctor
doctor: git_check npm_config_check npm_doctor npm_check toolchain_check

.PHONY: lint
lint: rustfmt_check prettier_check trimmer_check

.PHONY: analyze
analyze: npm_check clippy_check rustdoc_check

.PHONY: test
test: devcontainer_gate cargo_test

.PHONY: audit
audit: npm_audit

.PHONY: update
update: npm_config_check npm_update cargo_update

.PHONY: clean
clean: cargo_clean

.PHONY: distclean
distclean: clean deps_clean

.PHONY: all
all: debug release native

.PHONY: installdirs
installdirs:
	$(SUDO) install --directory --mode=0755 -- "$(DESTDIR)$(bindir)"

.PHONY: install
install: native installdirs
	$(SUDO) install --mode=0755 -- ./target/native/release/$(PROGRAM) "$(DESTDIR)$(bindir)/$(PROGRAM)"

.PHONY: uninstall
uninstall:
	$(SUDO) rm --force -- "$(DESTDIR)$(bindir)/$(PROGRAM)"

.PHONY: installcheck
installcheck:
	test -f "$(DESTDIR)$(bindir)/$(PROGRAM)"
	test -x "$(DESTDIR)$(bindir)/$(PROGRAM)"

.PHONY: postcreate
postcreate: deps_install toolchain_check

.PHONY: up
up: host_gate devcontainer_check
	mkdir --parents -- "$(DEVCONTAINER_TMPDIR)"
	env TMPDIR="$(DEVCONTAINER_TMPDIR)" devcontainer up --workspace-folder .

.PHONY: shell
shell: interactive_gate host_gate up
	devcontainer exec --workspace-folder . /bin/bash

.PHONY: stop
stop: host_gate
	docker compose -f "$(DEVCONTAINER_COMPOSE)" stop

.PHONY: down
down: host_gate
	docker compose -f "$(DEVCONTAINER_COMPOSE)" down --remove-orphans

.PHONY: rebuild
rebuild: host_gate devcontainer_check down
	mkdir --parents -- "$(DEVCONTAINER_TMPDIR)"
	env TMPDIR="$(DEVCONTAINER_TMPDIR)" devcontainer up --workspace-folder . --build-no-cache

.PHONY: nuke
nuke: distclean prune

.PHONY: prune
prune: host_gate
	docker compose -f "$(DEVCONTAINER_COMPOSE)" down --volumes --rmi all --remove-orphans

# Protected goals

.PHONY: host_gate
.SILENT: host_gate
host_gate:
	if test -e /.dockerenv; then printf '%s\n' 'host_gate: host only' >&2; exit 1; fi

.PHONY: devcontainer_gate
.SILENT: devcontainer_gate
devcontainer_gate:
	if test ! -e /.dockerenv; then printf '%s\n' 'devcontainer_gate: devcontainer only' >&2; exit 1; fi

.PHONY: interactive_gate
.SILENT: interactive_gate
interactive_gate:
	if test ! -t 0 || test ! -t 1; then printf '%s\n' 'interactive_gate: interactive only' >&2; exit 1; fi

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

.PHONY: toolchain_check
toolchain_check: ./rust-toolchain.toml
	rustup show
	rustc --version
	cargo --version

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

.PHONY: asan
asan: devcontainer_gate ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo test --locked --all-features --target x86_64-unknown-linux-gnuasan

.PHONY: msan
msan: devcontainer_gate ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo test --locked --all-features --target x86_64-unknown-linux-gnumsan

.PHONY: tsan
tsan: devcontainer_gate ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo test --locked --all-features --target x86_64-unknown-linux-gnutsan

.PHONY: sanitize
sanitize: asan msan tsan

.PHONY: debug
debug: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo build --locked --all-features

.PHONY: release
release: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo build --locked --release --all-features

.PHONY: native
native: ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	RUSTFLAGS='$(strip $(RUSTFLAGS) -C target-cpu=native)' cargo build --locked --release --all-features --target-dir ./target/native

.PHONY: dist_debug
dist_debug: debug
	install --directory --mode=0755 -- "./target/package/$(PACKAGE_DEBUG)" "./target/package/$(PACKAGE_DEBUG)/bin" ./dist
	install --mode=0755 -- ./target/debug/$(PROGRAM) "./target/package/$(PACKAGE_DEBUG)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_DEBUG)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_DEBUG).tar.gz" --directory=./target/package -- "$(PACKAGE_DEBUG)"

.PHONY: dist_release
dist_release: release
	install --directory --mode=0755 -- "./target/package/$(PACKAGE_RELEASE)" "./target/package/$(PACKAGE_RELEASE)/bin" ./dist
	install --mode=0755 -- ./target/release/$(PROGRAM) "./target/package/$(PACKAGE_RELEASE)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_RELEASE)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_RELEASE).tar.gz" --directory=./target/package -- "$(PACKAGE_RELEASE)"

.PHONY: dist_native
dist_native: native
	install --directory --mode=0755 -- "./target/package/$(PACKAGE_NATIVE)" "./target/package/$(PACKAGE_NATIVE)/bin" ./dist
	install --mode=0755 -- ./target/native/release/$(PROGRAM) "./target/package/$(PACKAGE_NATIVE)/bin/$(PROGRAM)"
	install --mode=0644 -- ./LICENSE "./target/package/$(PACKAGE_NATIVE)/LICENSE"
	tar --sort=name --mtime="@$(SOURCE_DATE_EPOCH)" --owner=0 --group=0 --numeric-owner --create --gzip --file="./dist/$(PACKAGE_NATIVE).tar.gz" --directory=./target/package -- "$(PACKAGE_NATIVE)"

.PHONY: dist
dist: dist_debug dist_release dist_native
	cd ./dist && sha256sum -- "$(PACKAGE_DEBUG).tar.gz" "$(PACKAGE_RELEASE).tar.gz" "$(PACKAGE_NATIVE).tar.gz" > ./SHA256SUMS

.PHONY: cargo_clean
cargo_clean:
	cargo clean
	rm --force --recursive --one-file-system -- ./dist "$(DEVCONTAINER_TMPDIR)"

.PHONY: git_check
git_check:
	test -z "$$(git ls-files --unmerged)"
	test -z "$$(git ls-files --cached --ignored --exclude-standard)"
	git diff --check
	git diff --cached --check
	git fsck --full --strict --no-dangling --no-progress

.PHONY: devcontainer_check
devcontainer_check: host_gate
	devcontainer read-configuration --workspace-folder . >/dev/null
	docker compose -f "$(DEVCONTAINER_COMPOSE)" config --quiet
	docker build --check --file ./.devcontainer/Dockerfile ./.devcontainer

# Private targets

./node_modules/.package-lock.json: ./.npmrc ./package.json ./package-lock.json
	$(MAKE) npm_install
