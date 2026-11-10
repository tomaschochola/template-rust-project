# AGENTS.md

Edit AGENTS.md and README.md only when explicitly requested.

Freely manage PLAN.md, NOTES.md, and ARCHITECTURE.md for your own work. Keep them gitignored and never commit them.

## Language

- Rust 1.99, edition 2024
- Rust standard library 1.99
- C library: GNU C Library 2.43

## Platform

- Operating system: GNU/Linux, Linux kernel 7.0
- Triple: x86_64-unknown-linux-gnu
- Architecture: x86-64
- Endianness: little-endian

## Toolchain

- rustc 1.99
- LLVM 23.1
- Cargo 1.99
- rustup 1.29
- GNU Make 4.4
- cargo test 1.99
- rustfmt 1.10
- Clippy 0.1
- rustdoc 1.99
- x86_64-unknown-linux-gnuasan 1.99
- x86_64-unknown-linux-gnumsan 1.99
- x86_64-unknown-linux-gnutsan 1.99

## Devcontainer

The development environment is configured in `.devcontainer/`. Manage it from the repository root on the host using the Makefile targets or directly through the `devcontainer`, `docker` and `docker compose` CLIs.

Use an available shell. Add `-eu` for sh or `-Eeuo pipefail` for Bash as needed.

```sh
# start
make up

# workspace command
devcontainer exec --workspace-folder . COMMAND ARG...

# workspace sh
devcontainer exec --workspace-folder . sh -c 'COMMAND ARG... | COMMAND ARG...'

# workspace bash
devcontainer exec --workspace-folder . bash -c 'COMMAND ARG... | COMMAND ARG...'

# sidecar command
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE COMMAND ARG...

# sidecar sh
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE sh -c 'COMMAND ARG... | COMMAND ARG...'

# sidecar bash
docker compose -f .devcontainer/docker-compose.yml exec -T SERVICE bash -c 'COMMAND ARG... | COMMAND ARG...'
```

### Services

`devcontainer` — `docker.io/library/ubuntu:26.04` Runs development tools and workspace commands.

`wiremock` — `docker.io/wiremock/wiremock:3.13.2` Mocks HTTP for development and automated tests.

## EditorConfig

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
indent_size = 4
indent_style = space
insert_final_newline = true
max_line_length = off
quote_type = single
trim_trailing_whitespace = true

[*.go]
indent_size = tab
indent_style = tab
tab_width = 8

[Makefile]
indent_size = tab
indent_style = tab
tab_width = 8
```

## Prettier

```js
import xml from '@prettier/plugin-xml';

export default Object.freeze({
    arrowParens: 'always',
    bracketSameLine: false,
    bracketSpacing: true,
    checkIgnorePragma: false,
    embeddedLanguageFormatting: 'auto',
    experimentalOperatorPosition: 'end',
    experimentalTernaries: false,
    htmlWhitespaceSensitivity: 'strict',
    insertPragma: false,
    jsxSingleQuote: false,
    objectWrap: 'preserve',
    plugins: Object.freeze([xml]),
    proseWrap: 'never',
    quoteProps: 'consistent',
    requirePragma: false,
    semi: true,
    singleAttributePerLine: true,
    singleQuote: true,
    trailingComma: 'all',
    vueIndentScriptAndStyle: true,
    xmlQuoteAttributes: 'double',
    xmlSelfClosingSpace: true,
    xmlSortAttributesByKey: false,
    xmlWhitespaceSensitivity: 'strict',
});
```
