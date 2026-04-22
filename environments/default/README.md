# Default environment notes

## Build concurrency defaults

The default environment intentionally caps Rust/Nix build parallelism to avoid
OOM kills in havn containers, where memory is often constrained relative to CPU
count.

Current defaults applied by this environment:

- `NIX_BUILD_CORES=4`
- `NIX_CONFIG` contains `cores = 4` and `max-jobs = 1`
- `CARGO_BUILD_JOBS=4`

These values prioritize predictable builds over peak throughput.

Quick check from inside the environment:

```bash
just show-build-parallelism
```

## Intentional override

If you need higher parallelism for a specific run, override per command:

```bash
NIX_BUILD_CORES=8 CARGO_BUILD_JOBS=8 NIX_CONFIG=$'cores = 8\nmax-jobs = 2' nix build .#target
```

Or enter a one-off shell override:

```bash
NIX_BUILD_CORES=8 CARGO_BUILD_JOBS=8 NIX_CONFIG=$'cores = 8\nmax-jobs = 2' nix develop
```

## Home Manager session prepare

The optional startup app `havn-session-prepare` activates Home Manager for the
current session user. It is intended for non-interactive container startup and
is safe to run repeatedly.

By default it resolves the Home Manager source from `devenv` and target
`homeConfigurations.default`.

What it does:

- validates `USER` and `HOME`
- builds `homeConfigurations.<target>.activationPackage` with `--impure`
- runs the activation script

Run manually:

```bash
nix run .#havn-session-prepare
```

When running outside havn (for example from this repo checkout), point it at the
local flake explicitly:

```bash
HAVN_HOME_MANAGER_FLAKE='.' nix run .#havn-session-prepare
```

Behavior controls:

- disable prepare step: `HAVN_SKIP_HOME_MANAGER=1`
- override target name: `HAVN_HOME_MANAGER_TARGET=<name>`
- override flake source: `HAVN_HOME_MANAGER_FLAKE='<flake-ref>'`
- control backup extension: `HAVN_HOME_MANAGER_BACKUP_EXT=<ext>` (default: `havn-backup`)
- disable backups entirely: `HAVN_HOME_MANAGER_BACKUP_EXT=none`

Manual Home Manager path:

```bash
USER="${USER:-$(id -un)}" HOME="${HOME:-/home/$(id -un)}" \
nix build --impure '.#homeConfigurations.default.activationPackage'
./result/activate
exec bash -l
```
