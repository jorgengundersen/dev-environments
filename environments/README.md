# environments

Environment entrypoints as self-contained flakes.

## Structure

Each environment directory (for example `default/`) should contain:

- `flake.nix` / `flake.lock`
- `default.nix` (composed shell membership)
- optional `home.nix` and `home-modules.nix`

## Creating a new environment

1. Create `environments/<name>/`.
2. Add `flake.nix` and import shared modules as plain path:

```nix
(inputs.import-tree.matchNot ".*flake.*" ../../shared)
```

3. Add `default.nix` with a `defaultProfile` list and a missing-shell guard.
4. Generate lock files:

```bash
./scripts/lock-environments.sh
```

5. Validate:

```bash
nix flake check ./environments/<name>
```
