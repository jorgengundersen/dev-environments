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

Check Home Manager session variable availability in your current shell:

```bash
just show-hm-session-vars
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
- resolves missing `USER` via `id -un`/`whoami`
- builds `homeConfigurations.<target>.activationPackage` with `--refresh --impure` by default
- runs the activation script

After activation, `devShells.default` attempts to source Home Manager session
variables automatically from common profile paths (including
`~/.nix-profile/.../hm-session-vars.sh`) when you enter the shell. If no
session-vars file exists, shell startup continues without failing and applies
non-overriding defaults for core editor/XDG/AI CLI variables.

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
- override refresh behavior: `HAVN_HOME_MANAGER_REFRESH=0` to disable refresh (default: enabled)
- control backup extension: `HAVN_HOME_MANAGER_BACKUP_EXT=<ext>` (default: `havn-backup`)
- disable backups entirely: `HAVN_HOME_MANAGER_BACKUP_EXT=none`

Manual Home Manager path:

```bash
USER="${USER:-$(id -un)}" HOME="${HOME:-/home/$(id -un)}" \
nix build --impure '.#homeConfigurations.default.activationPackage'
./result/activate
exec bash -l
```
