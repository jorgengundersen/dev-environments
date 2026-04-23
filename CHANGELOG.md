# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog, and this project follows Semantic Versioning.

## [Unreleased]

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

[Unreleased]: https://github.com/jorgengundersen/dev-environments/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/jorgengundersen/dev-environments/releases/tag/v0.1.1
[0.1.0]: https://github.com/jorgengundersen/dev-environments/releases/tag/v0.1.0
