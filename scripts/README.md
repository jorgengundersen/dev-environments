# Repository Scripts

This directory contains maintenance and automation scripts for this repository.

## Conventions

- Keep scripts focused on one task.
- Use kebab-case file names.
- Make shell scripts executable and include:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

## Available Scripts

- `scripts/check-default-flake.sh` - Run `nix flake check` for `environments/default`.
- `scripts/check-environment-flakes.sh` - Run `nix flake check` for each flake in `environments/*`.
- `scripts/format-nix.sh` - Format all tracked `.nix` files with `nixfmt`.
- `scripts/check-all.sh` - Run environment checks, formatting checks, and available Nix linters.
- `scripts/lock-environments.sh` - Update `flake.lock` in each environment flake directory.

## Usage

Run scripts from the repository root:

```bash
./scripts/check-all.sh

# update all environment lock files
./scripts/lock-environments.sh

# update lock files while updating one input
./scripts/lock-environments.sh --update-input nixpkgs

# full lockfile refresh (mapped to nix flake update)
./scripts/lock-environments.sh --recreate-lock-file
```
