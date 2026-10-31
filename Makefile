# Makefile
SHELL := bash

GNUMAKEFLAGS ?=

MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

.SHELLFLAGS := -Eeuo pipefail -c

.DELETE_ON_ERROR:
.SUFFIXES:
.NOTPARALLEL:

# Default
.DEFAULT_GOAL := never

.PHONY: never
.SILENT: never
never:
	printf '%s\n' 'No default target. Specify a target explicitly.' >&2
	exit 1

# Variables
CARGO_TERM_COLOR := never
COMPOSE_PROJECT_NAME := $(shell printf 'dc-%s-%s' "$$(basename -- "$$(pwd -P)" | LC_ALL=C tr '[:upper:]' '[:lower:]' | LC_ALL=C tr -cs 'a-z0-9' '-' | sed -e 's/^-*//' -e 's/-*$$//' -e 's/^$$/workspace/' | cut -c 1-32 | sed 's/-*$$//')" "$$(printf '%s' "$$(pwd -P)" | sha256sum | cut -c 1-16)")
LC_ALL := C.UTF-8
SOURCE_DATE_EPOCH := $(shell git log -1 --format=%ct 2>/dev/null || echo 0)
VERSION := $(shell v=$$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0); v=$${v#v}; echo "$$v")

bindir ?= $(exec_prefix)/bin
DESTDIR ?=
exec_prefix ?= $(prefix)
prefix ?= /usr/local
SUDO ?= sudo

export CARGO_TERM_COLOR
export COMPOSE_PROJECT_NAME
export LC_ALL
export SOURCE_DATE_EPOCH
export VERSION

# Phony
.PHONY: all
all: debug release

.PHONY: analyze
analyze: npm_check clippy_check rustdoc_check

.PHONY: asan
asan: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo test --locked --all-targets --target x86_64-unknown-linux-gnuasan
	cargo test --locked --doc --target x86_64-unknown-linux-gnuasan
	cargo test --locked --all-targets --all-features --target x86_64-unknown-linux-gnuasan
	cargo test --locked --doc --all-features --target x86_64-unknown-linux-gnuasan

.PHONY: audit
audit: npm_audit

.PHONY: cargo_clean
cargo_clean:
	cargo clean

.PHONY: cargo_fetch
cargo_fetch: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo fetch --locked

.PHONY: cargo_fix
cargo_fix: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo fix --locked --all-targets --allow-dirty
	cargo fix --locked --all-targets --all-features --allow-dirty

.PHONY: cargo_test
cargo_test: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo test --locked --all-targets
	cargo test --locked --doc
	cargo test --locked --all-targets --all-features
	cargo test --locked --doc --all-features

.PHONY: cargo_update
cargo_update: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo update

.PHONY: check
check: doctor lint analyze test audit

.PHONY: clean
clean: cargo_clean
	rm --force --recursive --one-file-system -- ./dist ./temp ./temporary ./tmp ./.temp ./.temporary ./.tmp

.PHONY: clippy_check
clippy_check: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo clippy --locked --all-targets
	cargo clippy --locked --all-targets --all-features

.PHONY: clippy_fix
clippy_fix: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo clippy --fix --locked --all-targets --allow-dirty
	cargo clippy --fix --locked --all-targets --all-features --allow-dirty

.PHONY: debug
debug: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo build --locked

.PHONY: deps_clean
deps_clean: npm_clean

.PHONY: deps_install
deps_install: npm_install cargo_fetch

.PHONY: devcontainer_check
devcontainer_check:
	devcontainer read-configuration --workspace-folder . >/dev/null
	docker compose -f "./.devcontainer/docker-compose.yml" config --quiet
	docker build --check --file ./.devcontainer/Dockerfile ./.devcontainer

.PHONY: dirclean
dirclean:
	fd --hidden --exclude .git --type directory --print0 | sort --zero-terminated --reverse | xargs --null --no-run-if-empty rmdir --ignore-fail-on-non-empty --

.PHONY: dist
dist: dist_debug dist_release

.PHONY: dist_debug
dist_debug: debug
	rm --force --recursive --one-file-system -- "./target/package/template-rust-project-$(VERSION)-debug"
	install --directory --mode=0755 -- "./target/package/template-rust-project-$(VERSION)-debug" "./target/package/template-rust-project-$(VERSION)-debug/bin" ./dist
	install --mode=0755 -- ./target/debug/template-rust-project "./target/package/template-rust-project-$(VERSION)-debug/bin/template-rust-project"
	install --mode=0644 -- ./LICENSE "./target/package/template-rust-project-$(VERSION)-debug/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-rust-project-$(VERSION)-debug.tar.gz" --directory=./target/package --no-recursion -- "template-rust-project-$(VERSION)-debug" "template-rust-project-$(VERSION)-debug/LICENSE" "template-rust-project-$(VERSION)-debug/bin" "template-rust-project-$(VERSION)-debug/bin/template-rust-project"
	cd ./dist && sha256sum -- "template-rust-project-$(VERSION)-debug.tar.gz" > "template-rust-project-$(VERSION)-debug.tar.gz.sha256"

.PHONY: dist_release
dist_release: release
	rm --force --recursive --one-file-system -- "./target/package/template-rust-project-$(VERSION)-release"
	install --directory --mode=0755 -- "./target/package/template-rust-project-$(VERSION)-release" "./target/package/template-rust-project-$(VERSION)-release/bin" ./dist
	install --mode=0755 -- ./target/release/template-rust-project "./target/package/template-rust-project-$(VERSION)-release/bin/template-rust-project"
	install --mode=0644 -- ./LICENSE "./target/package/template-rust-project-$(VERSION)-release/LICENSE"
	bsdtar --create --auto-compress --mtime="@$(SOURCE_DATE_EPOCH)" --uid=0 --gid=0 --numeric-owner --no-acls --no-xattrs --no-fflags --options='gzip:!timestamp' --file="./dist/template-rust-project-$(VERSION)-release.tar.gz" --directory=./target/package --no-recursion -- "template-rust-project-$(VERSION)-release" "template-rust-project-$(VERSION)-release/LICENSE" "template-rust-project-$(VERSION)-release/bin" "template-rust-project-$(VERSION)-release/bin/template-rust-project"
	cd ./dist && sha256sum -- "template-rust-project-$(VERSION)-release.tar.gz" > "template-rust-project-$(VERSION)-release.tar.gz.sha256"

.PHONY: distclean
distclean: clean deps_clean

.PHONY: doctor
doctor: git_check npm_config_check npm_doctor npm_check toolchain_check

.PHONY: down
down:
	docker compose -f "./.devcontainer/docker-compose.yml" down --remove-orphans

.PHONY: fix
fix: cargo_fix clippy_fix rustfmt_fix prettier_fix trimmer_fix

.PHONY: git_check
git_check:
	test -z "$$(git ls-files --unmerged)"
	test -z "$$(git ls-files --cached --ignored --exclude-standard)"
	git diff --check
	git diff --cached --check
	git fsck --full --strict --no-dangling --no-progress

.PHONY: install
install: release installdirs
	$(SUDO) install --mode=0755 -- ./target/release/template-rust-project "$(DESTDIR)$(bindir)/template-rust-project"

.PHONY: installcheck
installcheck:
	test -f "$(DESTDIR)$(bindir)/template-rust-project"
	test -x "$(DESTDIR)$(bindir)/template-rust-project"

.PHONY: installdirs
installdirs:
	$(SUDO) install --directory --mode=0755 -- "$(DESTDIR)$(bindir)"

.PHONY: interactive_gate
.SILENT: interactive_gate
interactive_gate:
	if test ! -t 0 || test ! -t 1; then printf '%s\n' 'interactive_gate: interactive only' >&2; exit 1; fi

.PHONY: lint
lint: rustfmt_check prettier_check trimmer_check

.PHONY: msan
msan: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo test --locked --all-targets --target x86_64-unknown-linux-gnumsan
	cargo test --locked --doc --target x86_64-unknown-linux-gnumsan
	cargo test --locked --all-targets --all-features --target x86_64-unknown-linux-gnumsan
	cargo test --locked --doc --all-features --target x86_64-unknown-linux-gnumsan

.PHONY: npm_audit
npm_audit: npm_config_check ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm audit --ignore-scripts --audit-level=critical --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_check
npm_check: npm_config_check ./node_modules/.package-lock.json
	npm ci --dry-run --ignore-scripts --audit=false --install-links --include=prod --include=dev --include=peer --include=optional
	npm ls --all --install-links --include=prod --include=dev --include=peer --include=optional >/dev/null

.PHONY: npm_clean
npm_clean:
	rm --force --recursive --one-file-system -- ./node_modules

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

.PHONY: npm_install
npm_install: npm_config_check ./package.json ./package-lock.json
	npm ci --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: npm_update
npm_update: npm_config_check ./package.json ./package-lock.json npm_clean
	npm update --ignore-scripts --install-links --include=prod --include=dev --include=peer --include=optional

.PHONY: nuke
nuke: distclean prune xfd dirclean

.PHONY: port ports url urls
.SILENT: port ports url urls
port ports url urls:
	printf 'Project: %s\n' "$$COMPOSE_PROJECT_NAME"
	printf '%-20s %-12s %s\n' 'SERVICE' 'PORT' 'URL'
	docker compose -f "./.devcontainer/docker-compose.yml" ps --format '{{$$service := .Service}}{{range .Publishers}}{{if .PublishedPort}}{{printf "%-20s %-12s http://%s:%d" $$service (printf "%d/%s" .TargetPort .Protocol) .URL .PublishedPort}}{{println}}{{end}}{{end}}' | sed '/^$$/d' | sort

.PHONY: postcreate
postcreate: deps_install toolchain_check

.PHONY: prettier_check
prettier_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --no --ignore-scripts -- prettier -c .

.PHONY: prettier_fix
prettier_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json ./prettier.config.js
	npm exec --no --ignore-scripts -- prettier -w .

.PHONY: prune
prune:
	docker compose -f "./.devcontainer/docker-compose.yml" down --volumes --rmi local --remove-orphans

.PHONY: rebuild
rebuild: devcontainer_check down | $(CURDIR)/.tmp
	TMPDIR="$(CURDIR)/.tmp" devcontainer up --workspace-folder . --build-no-cache

.PHONY: release
release: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo build --locked --release

.PHONY: rustdoc_check
rustdoc_check: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo doc --locked --no-deps --document-private-items
	cargo doc --locked --all-features --no-deps --document-private-items

.PHONY: rustfmt_check
rustfmt_check: ./.cargo/config.toml ./Cargo.toml ./rust-toolchain.toml ./rustfmt.toml
	cargo fmt --all --check

.PHONY: rustfmt_fix
rustfmt_fix: ./.cargo/config.toml ./Cargo.toml ./rust-toolchain.toml ./rustfmt.toml
	cargo fmt --all

.PHONY: sanitize
sanitize: asan msan tsan

.PHONY: shell
shell: interactive_gate up
	devcontainer exec --workspace-folder . /bin/bash

.PHONY: stop
stop:
	docker compose -f "./.devcontainer/docker-compose.yml" stop

.PHONY: test
test: cargo_test

.PHONY: toolchain_check
toolchain_check: ./rust-toolchain.toml
	rustup show
	rustc --version
	cargo --version

.PHONY: trimmer_check
trimmer_check: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --no --ignore-scripts -- tooling-trimmer check .

.PHONY: trimmer_fix
trimmer_fix: ./node_modules/.package-lock.json ./package.json ./package-lock.json
	npm exec --no --ignore-scripts -- tooling-trimmer fix .

.PHONY: tsan
tsan: ./.cargo/config.toml ./Cargo.toml ./Cargo.lock ./rust-toolchain.toml
	cargo test --locked --all-targets --target x86_64-unknown-linux-gnutsan
	cargo test --locked --doc --target x86_64-unknown-linux-gnutsan
	cargo test --locked --all-targets --all-features --target x86_64-unknown-linux-gnutsan
	cargo test --locked --doc --all-features --target x86_64-unknown-linux-gnutsan

.PHONY: uninstall
uninstall:
	$(SUDO) rm --force -- "$(DESTDIR)$(bindir)/template-rust-project"

.PHONY: up
up: devcontainer_check | $(CURDIR)/.tmp
	TMPDIR="$(CURDIR)/.tmp" devcontainer up --workspace-folder .

.PHONY: update
update: npm_config_check npm_update cargo_update

.PHONY: xfd
xfd:
	git clean -Xfd

# Non-phony
$(CURDIR)/.tmp:
	mkdir --parents -- "$@"

./node_modules/.package-lock.json: ./.npmrc ./package.json ./package-lock.json
	$(MAKE) npm_install
