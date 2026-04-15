# User Guide

## What this repo gives you

- Reproducible dev environments via Nix flakes.
- Multiple shell entrypoints (`default`, `minimal`, tool-specific shells like `go`, `python`, `claude`).
- One lockfile at repo root (`flake.lock`) shared by all entrypoints.

## Prerequisites

- Nix with flakes enabled.

## Daily usage

Enter full environment:

```bash
nix develop
```

Enter a specific environment:

```bash
nix develop .#minimal
```

Enter a tool-focused shell:

```bash
nix develop .#go
nix develop .#python
nix develop .#neovim
```

Use from another repo:

```bash
nix develop github:jorgengundersen/dev-environments#minimal
```

## How environment composition works

- Tool/aspect shells are defined in feature files (for example `languages/go.nix`, `shell/prompt.nix`).
- Composed environments (`default`, `minimal`) read membership from `environments/profiles.json`.
- `default` and `minimal` are entrypoints in `environments/default.nix` and `environments/minimal.nix`.

## Build behavior (important for containers)

- `nix develop .#minimal` realizes `minimal` closure.
- It does not build `default` unless referenced.
- Nix still evaluates the flake graph, so unrelated broken modules can fail evaluation.

## Add a new tool shell

1. Add a new aspect file (example: `languages/zig.nix`) with `devShells.zig`.
2. Validate:

```bash
nix flake check
```

3. Optional: include it in composed environments by editing `environments/profiles.json`.

## Add a new composed environment

1. Add profile in `environments/profiles.json` (example: `backend`).
2. Add entrypoint file in `environments/` (example: `environments/backend.nix`) mapping profile names to `inputsFrom`.
3. Use it:

```bash
nix develop .#backend
```

## Home Manager (optional)

Build and activate exported home configuration:

```bash
nix build .#homeConfigurations.default.activationPackage
./result/activate
```

## Troubleshooting

- If a shell fails on one platform, guard unsupported packages with `lib.optionals`/`lib.mkIf` in the relevant module.
- If Nix says a new file is not tracked, `git add` it so flake evaluation can see it.
