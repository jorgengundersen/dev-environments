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

Current environments:

- `environments/default/flake.nix`
- `environments/default/default.nix`
- `environments/default/bash.nix`
- `environments/default/home-modules.nix`
- `environments/default/home.nix`
- `environments/default/flake.lock`
- `environments/monarch/flake.nix`
- `environments/monarch/default.nix`
- `environments/monarch/bash.nix`
- `environments/monarch/home-modules.nix`
- `environments/monarch/home.nix`
- `environments/monarch/flake.lock`

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

Editor modules that expose both a dev shell and Home Manager configuration must
keep their shell runtime aligned with the Home Manager configuration. In
particular, `devShells.neovim` must provide the Neovim plugins required by the
Home Manager `init.lua`, because composed shells may put the dev-shell `nvim`
before Home Manager's profile wrapper in `PATH`.

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

Monarch Alpha usage:

```bash
MONARCH_DEVENV_FLAKE="github:jorgengundersen/dev-environments?dir=environments/monarch"
nix develop "$MONARCH_DEVENV_FLAKE"
nix run "$MONARCH_DEVENV_FLAKE#monarch-session-prepare"
nix flake check "$MONARCH_DEVENV_FLAKE"
```

`monarch-session-prepare` must choose a platform-appropriate Home Manager target
by default: `homeConfigurations.default` on `x86_64-linux`, and
`homeConfigurations.${USER}@aarch64` on `aarch64-linux`. An explicit
`MONARCH_HOME_MANAGER_TARGET` always overrides this default.

The Monarch environment must include Neovim in its default shell and Home
Manager module selection, with `EDITOR`/`VISUAL` defaulting to `nvim` when not
otherwise set.

The Monarch environment must keep persistent tool state below XDG locations and
provides non-overriding defaults for `PI_CODING_AGENT_DIR`, `CODEX_HOME`,
`GH_CONFIG_DIR`, and `CLAUDE_CONFIG_DIR` below `$XDG_STATE_HOME`.

The Monarch environment must include `$HOME/.local/bin` on `PATH` so
user-local tools and container-installed shortcuts remain available in
interactive and Nix development shells.

The Monarch environment must provide Python 3.14 and a `monarch` command on
`PATH`. The `monarch` command must run the live mounted Monarch Alpha source at
`/workspace/monarch-alpha`, store its uv project environment outside the
bind-mounted project checkout by default, and disable uv-managed Python
downloads. Its default uv project environment is:

```text
$XDG_STATE_HOME/monarch-alpha/venv
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
