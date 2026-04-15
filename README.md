# dev-environments

Composable development environments with shared Nix modules and environment-specific flake entrypoints.

## Current Layout

- `shared/` contains reusable composable modules (`devShells.<name>` and optional `flake.homeModules.<name>`).
- `environments/default/` is the default environment entrypoint and owns:
  - `flake.nix` / `flake.lock`
  - environment composition (`default.nix`)
  - Home Manager assembly (`home.nix`, `home-modules.nix`)

## Quick Start

Use the default environment flake:

```bash
# enter full default environment
nix develop ./environments/default

# enter a tool-specific shell exposed by shared modules
nix develop ./environments/default#go
nix develop ./environments/default#python
nix develop ./environments/default#claude
```

From another repo via GitHub:

```bash
nix develop "github:jorgengundersen/dev-environments?dir=environments/default"
nix develop "github:jorgengundersen/dev-environments?dir=environments/default#go"
```

## Home Manager

Build and activate Home Manager from the default environment flake:

```bash
nix build ./environments/default#homeConfigurations.default.activationPackage
./result/activate
```

To customize user/home targets, edit `environments/default/home.nix`.

## Add a Module

1. Add a `.nix` module under `shared/`.
2. Expose a shell as `devShells.<name>`.
3. Optionally add `flake.homeModules.<name>` for persistent config.
4. If it belongs in the composed default shell, add it to `environments/default/default.nix`.
5. Validate with:

```bash
nix flake check ./environments/default
```
