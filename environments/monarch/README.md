# Monarch Alpha environment

Nix flake entrypoint for isolated Monarch Alpha agent workspaces.

## Flake reference

From this repository checkout:

```bash
MONARCH_DEVENV_FLAKE=./environments/monarch
```

From GitHub, pin to an immutable tag or commit for reproducibility:

```bash
MONARCH_DEVENV_FLAKE="github:jorgengundersen/dev-environments/<commit-or-tag>?dir=environments/monarch"
```

For moving-tip testing on the default branch:

```bash
MONARCH_DEVENV_FLAKE="github:jorgengundersen/dev-environments?dir=environments/monarch"
```

## Contract

```bash
nix develop "$MONARCH_DEVENV_FLAKE"
nix run "$MONARCH_DEVENV_FLAKE#monarch-session-prepare"
nix flake check "$MONARCH_DEVENV_FLAKE"
```

The default shell provides the required Monarch user-space tools and sets
non-overriding XDG defaults. Agent state resolves under `$XDG_STATE_HOME`:

- `PI_CODING_AGENT_DIR=$XDG_STATE_HOME/pi/agent`
- `CODEX_HOME=$XDG_STATE_HOME/codex`
- `GH_CONFIG_DIR=$XDG_STATE_HOME/gh`
- `CLAUDE_CONFIG_DIR=$XDG_STATE_HOME/claude`

## Session preparation controls

`monarch-session-prepare` builds and runs a platform-appropriate Home Manager
activation package for the current `USER`/`HOME` with `--impure`: `default` on
`x86_64-linux`, and `${USER}@aarch64` on `aarch64-linux`. It is safe to rerun.

Controls:

- `MONARCH_SKIP_HOME_MANAGER=1` disables activation.
- `MONARCH_HOME_MANAGER_TARGET=<target>` overrides the platform default Home Manager target.
- `MONARCH_HOME_MANAGER_FLAKE=<flake-ref>` overrides the flake source.
- `MONARCH_HOME_MANAGER_REFRESH=1` adds `--refresh` while building activation.
- `MONARCH_HOME_MANAGER_BACKUP_EXT=<ext>` controls Home Manager backup extension (`monarch-backup`).
- `MONARCH_HOME_MANAGER_BACKUP_EXT=none` disables backups.

The beads executable is `bd`.
