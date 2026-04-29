# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

## [Unreleased]

### Changed

- `havn-session-prepare` no longer passes `--refresh` by default; enable it explicitly with `HAVN_HOME_MANAGER_REFRESH=1`.

## [0.1.3] - 2026-04-27

### Added

- Added `less` to the shared `core` development shell package set.

### Fixed

- `devShells.default` now sources Home Manager `hm-session-vars.sh` from common profile paths when available, so variables like `EDITOR`/`CODEX_HOME` are present in interactive shell entry points (including havn flows) without login-shell workarounds.
- `devShells.default` and `devShells.pi` now apply non-overriding fallback exports for XDG/editor/AI variables when Home Manager session files are absent.
- Removed default `PI_PACKAGE_DIR` exports so `pi` can resolve its bundled package metadata from the installed package path instead of failing on missing `~/.local/state/pi/packages/package.json`.
- `devShells.default` and `devShells.codex` now create `CODEX_HOME` (and related XDG state directories) on shell entry so `codex` does not fail when the configured home path is missing.
- `devShells.claude`, `devShells.copilot`, and `devShells.pi` now ensure their configured state/cache directories exist on shell entry to avoid missing-path startup failures when Home Manager activation did not pre-create them.

## [0.1.2] - 2026-04-24

### Changed

- Updated Home Manager Neovim and Git module options to current keys to remove deprecation warnings.
- Pinned Home Manager defaults for `programs.neovim.withRuby`, `programs.neovim.withPython3`, and `programs.git.signing.format` to preserve current behavior.
- Added `EDITOR=nvim` and `VISUAL=nvim` to shared shell session variables.

### Fixed

- `havn-session-prepare` now supports `HAVN_HOME_MANAGER_REFRESH` as an explicit refresh override while keeping refresh enabled by default for nested Home Manager builds.
- Documented refresh behavior and override controls for `havn-session-prepare` in `environments/default/README.md`.

## [0.1.1] - 2026-04-23

### Added

- Home Manager session variable defaults for AI CLIs to use XDG paths in the default environment:
  - `CODEX_HOME=$XDG_STATE_HOME/codex`
  - `CLAUDE_CONFIG_DIR=$XDG_STATE_HOME/claude`
  - `COPILOT_HOME=$XDG_STATE_HOME/copilot`
  - `COPILOT_CACHE_HOME=$XDG_CACHE_HOME/copilot`
  - `PI_CODING_AGENT_DIR=$XDG_STATE_HOME/pi/agent`
  - `PI_PACKAGE_DIR=$XDG_STATE_HOME/pi/packages`

## [0.1.0] - 2026-04-22

### Added

- Initial tagged release for the repository.
- Composable Nix dev environments under `environments/default` and shared modules under `shared/`.
- Home Manager assembly for the default environment.
- Optional `apps.<system>.havn-session-prepare` startup hook for havn sessions.
- Repository maintenance scripts and documented validation workflow.

[Unreleased]: https://github.com/jorgengundersen/dev-environments/compare/v0.1.3...HEAD
[0.1.3]: https://github.com/jorgengundersen/dev-environments/releases/tag/v0.1.3
[0.1.2]: https://github.com/jorgengundersen/dev-environments/releases/tag/v0.1.2
[0.1.1]: https://github.com/jorgengundersen/dev-environments/releases/tag/v0.1.1
[0.1.0]: https://github.com/jorgengundersen/dev-environments/releases/tag/v0.1.0
