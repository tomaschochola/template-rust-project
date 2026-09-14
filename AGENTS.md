# template-rust-project

Rust project template: library and binary crates with strict lints and cross targets.

## Stack

- Language: Rust 1.98
- Runtime: GNU/Linux
- Libraries: none (template skeleton)
- Package managers: cargo, npm (JS tooling side)

## Toolchain

- Format: rustfmt, prettier, trimmer
- Lint: clippy
- Test: cargo test
- Audit: npm audit

## Devcontainer

- Base: official Rust
- User: devcontainer
- Sidecars: none
- Up: `make up`
- Execute: `devcontainer exec --workspace-folder . <command>`
- Down: `make down`

## Makefile

- `update` — refresh locks, only tool that may touch them
- `fix` — auto-fix, may dirty tree
- `check` — full gate: doctor + lint + analyze + test + dist + audit
- `doctor` — tree and toolchain ok
- `lint` — rustfmt + prettier + trimmer checks
- `analyze` — npm + clippy + rustdoc checks
- `test` — cargo test suite
- `dist` — release artifacts
- `audit` — npm audit
- `install` — install to prefix (`installdirs`, `uninstall`, `installcheck`)
- `postcreate` — first-time setup, runs automatically on create
- `stop` — stop container, keep it
- `down` — stop and remove container
- `clean` — drop generated files
- `distclean` — drop everything rebuildable
- `rebuild` — full rebuild, only when broken

## Layout

├── Makefile
├── .editorconfig
├── .devcontainer/
├── Cargo.toml
├── rust-toolchain.toml
├── rustfmt.toml
├── package.json
├── prettier.config.js
├── LICENSE
├── AUTHORS.md
├── src/
│   └── main.rs
├── benches/
└── tests/
