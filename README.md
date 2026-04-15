# dev-environments

Composable development environments with shared Nix modules and environment-specific flake entrypoints.

## Current Layout

- `shared/` contains reusable composable modules (`devShells.<name>` and optional `flake.homeModules.<name>`).
- `environments/default/` is the default environment entrypoint and owns:
  - `flake.nix` / `flake.lock`
  - environment composition (`default.nix`)
  - Home Manager assembly (`home.nix`, `home-modules.nix`)
  - default-only shell behavior (`bash.nix`)

`environments/default/default.nix` includes a guard that fails with a clear error if the composed `defaultProfile` references a missing `devShells.<name>`.

## Quick Start

Use the default environment flake:

```bash
# enter full default environment
nix develop ./environments/default

# enter a tool-specific shell exposed by shared modules
nix develop ./environments/default#go
nix develop ./environments/default#python
nix develop ./environments/default#claude
nix develop ./environments/default#playwright
nix develop ./environments/default#just
```

From another repo via GitHub:

```bash
nix develop "github:jorgengundersen/dev-environments?dir=environments/default"
nix develop "github:jorgengundersen/dev-environments?dir=environments/default#go"
```

Pin to a specific revision when you need reproducibility:

```bash
nix develop "github:jorgengundersen/dev-environments/<commit-or-tag>?dir=environments/default"
```

See `docs/user-guide.md` for cross-repo usage patterns and how to create additional environment entrypoints.

## Repository Scripts

Maintenance scripts live in `scripts/`.

- See `scripts/README.md` for conventions and available scripts.
- Common commands:

```bash
./scripts/check-all.sh
./scripts/lock-environments.sh
```

## Git Hooks

`lefthook` runs pre-commit checks for staged files:

- `nixfmt` (auto-format staged `*.nix` and restage)
- `statix` and `deadnix` for Nix linting
- `shellcheck` for staged `*.sh`

## Home Manager

Build and activate Home Manager from the default environment flake:

```bash
nix build ./environments/default#homeConfigurations.default.activationPackage
./result/activate
```

Home targets derive `username`/`homeDirectory` from `USER` and `HOME` in `environments/default/home.nix` (no hardcoded user paths).

The shared Bash module (`shared/shell/bash.nix`) carries only baseline shell policy for broad reuse.

Default-only shell behavior lives in `environments/default/bash.nix` and supports runtime injection via:

- `DEVENV_CONFIG_ROOT` (directory; default: `${XDG_CONFIG_HOME:-$HOME/.config}/dev-environments`)
- `DEVENV_BASH_SOURCES` (colon-separated source file list)

Default source list when `DEVENV_BASH_SOURCES` is unset:

- `$DEVENV_CONFIG_ROOT/default.local.sh`
- `$DEVENV_CONFIG_ROOT/default.secrets.sh`

## Add a Module

1. Add a `.nix` module under `shared/`.
2. Expose a shell as `devShells.<name>`.
3. Optionally add `flake.homeModules.<name>` for persistent config.
4. If it belongs in the composed default shell, add it to `environments/default/default.nix`.
5. Validate with:

```bash
nix flake check ./environments/default
```
