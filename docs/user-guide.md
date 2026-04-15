# User Guide

## What this repo gives you

- Reusable module library under `shared/`
- A self-contained default environment flake under `environments/default/`
- Tool shells (`#go`, `#python`, etc.) plus a composed `default` shell

## Prerequisites

- Nix with flakes enabled.

## Daily usage

Enter the composed default shell:

```bash
nix develop ./environments/default
```

Enter a specific tool shell from the same flake:

```bash
nix develop ./environments/default#go
nix develop ./environments/default#python
nix develop ./environments/default#neovim
```

Use from another repo:

```bash
nix develop "github:jorgengundersen/dev-environments?dir=environments/default"
```

## Composition model

- Shared module definitions live in `shared/`.
- The default composed shell membership is defined in `environments/default/default.nix`.
- `environments/default/default.nix` maps that membership into `devShells.default`.
- Composition is validated in `environments/default/default.nix`; missing shell names fail fast with an explicit error.

## Home Manager

Build and activate:

```bash
nix build ./environments/default#homeConfigurations.default.activationPackage
./result/activate
```

Home targets are defined in `environments/default/home.nix` and derive `username`/`homeDirectory` from `USER`/`HOME` instead of hardcoded paths.

Baseline shell behavior is defined in `shared/shell/bash.nix` via Home Manager.

Default-specific shell behavior is defined in `environments/default/bash.nix`.

Runtime injection contract:

- `DEVENV_CONFIG_ROOT`: optional directory for default source files (defaults to `${XDG_CONFIG_HOME:-$HOME/.config}/dev-environments`)
- `DEVENV_BASH_SOURCES`: optional colon-separated source file list

If `DEVENV_BASH_SOURCES` is unset, the shell uses:

- `$DEVENV_CONFIG_ROOT/default.local.sh`
- `$DEVENV_CONFIG_ROOT/default.secrets.sh`

## Add a new module

1. Add a new file under `shared/` (example: `shared/languages/zig.nix`) with `devShells.zig`.
2. Optional: add `flake.homeModules.zig` in the same file.
3. If you want it in the composed shell, add `zig` to `environments/default/default.nix`.
4. Validate:

```bash
nix flake check ./environments/default
```
