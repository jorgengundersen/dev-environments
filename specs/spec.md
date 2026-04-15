# Dev Environments Specification

## Purpose

This repository defines reusable Nix modules and environment-specific flake entrypoints.

- `shared/` is the reusable module library.
- `environments/<name>/` owns each environment's flake entrypoint and composition.

The repo focuses on toolchains and user-space developer configuration. Container/runtime orchestration is out of scope.

## Architecture

### 1) Shared Module Layer

`shared/` contains composable flake-parts modules grouped by feature:

- `shared/core.nix`
- `shared/languages/*.nix`
- `shared/editors/*.nix`
- `shared/shell/*.nix`
- `shared/git/*.nix`
- `shared/ai/*.nix`
- `shared/docs/*.nix`
- `shared/data/*.nix`
- `shared/quality/*.nix`
- `shared/utils/*.nix`

Each module may expose:

- `perSystem.devShells.<name>`
- optional `flake.homeModules.<name>`

Modules must remain evaluation-safe across supported systems.

### 2) Environment Entrypoint Layer

Each environment is a self-contained subflake in `environments/<name>/`.

Current environment:

- `environments/default/flake.nix`
- `environments/default/default.nix`
- `environments/default/bash.nix`
- `environments/default/home-modules.nix`
- `environments/default/home.nix`
- `environments/default/flake.lock`

`environments/default/flake.nix` imports `shared/` via `import-tree` and composes outputs for that environment.

### 3) Composition Source of Truth

Composition membership is defined directly in each environment entrypoint.

- `environments/default/default.nix` defines the module list used to build `devShells.default`.
- Additional environments should define their own composition locally unless intentional sharing is introduced.

`environments/default/default.nix` must validate composition references before building the composed shell. Missing `devShells.<name>` references are treated as configuration errors and fail with a clear message.

## Home Manager Model

Home Manager is assembled per environment (not globally at repo root).

- Module registry is declared in `environments/default/home-modules.nix`.
- Target home configurations are declared in `environments/default/home.nix`.

Home targets are parameterized as a list of `{ name, system, username, homeDirectory }` records.

In `environments/default/home.nix`, `username` and `homeDirectory` are derived from `USER` and `HOME` (no repository-bound hardcoded user paths).

For the default environment, baseline Bash behavior is declared in `shared/shell/bash.nix` for broad reuse, while default-specific Bash behavior is declared in `environments/default/bash.nix`.

Default Bash runtime injection contract:

- `DEVENV_CONFIG_ROOT`: optional directory used to derive default source paths (default `${XDG_CONFIG_HOME:-$HOME/.config}/dev-environments`)
- `DEVENV_BASH_SOURCES`: optional colon-separated file list to source in order

When `DEVENV_BASH_SOURCES` is unset, the default source list is:

- `$DEVENV_CONFIG_ROOT/default.local.sh`
- `$DEVENV_CONFIG_ROOT/default.secrets.sh`

## Usage Contract

Local usage:

```bash
nix develop ./environments/default
nix develop ./environments/default#go
nix flake check ./environments/default
```

Remote usage:

```bash
nix develop "github:jorgengundersen/dev-environments?dir=environments/default"
```

## Design Rules

1. Reusable modules belong in `shared/`.
2. Environment-specific wiring belongs in `environments/<name>/`.
3. Keep only one active source of truth for a given composition.
4. Do not store plaintext secrets in git or in Nix expressions that land in the Nix store.
5. Prefer strict types over raw types for module options where possible.

## Non-Goals

- Docker image/runtime orchestration
- NixOS system-level configuration
- Project-specific dependency management
