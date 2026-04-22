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
