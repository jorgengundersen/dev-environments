- use conventional commits
- see @scripts/ for useful scripts

## Project map

- `README.md` — repository overview, quick start, versioning, and module-add workflow.
- `docs/` — practical user/operator docs; start with `docs/README.md` and `docs/user-guide.md`.
- `specs/` — architecture and contract docs; update `specs/spec.md` before behavior changes.
- `shared/` — reusable Nix modules grouped by domain; see `shared/README.md` for the domain index.
  - `shared/ai/` — coding agents and LLM CLI tooling.
  - `shared/browser/` — browser automation tooling.
  - `shared/data/` — local database/data workflow tooling.
  - `shared/docs/` — docs, diagrams, and rendering/publishing tooling.
  - `shared/editors/` — editor tooling and editor config modules.
  - `shared/git/` — git workflow tooling.
  - `shared/languages/` — language runtimes and toolchains.
  - `shared/quality/` — linting, formatting, scanning, and quality checks.
  - `shared/shell/` — shell UX and interactive shell behavior.
  - `shared/utils/` — cross-domain utilities only when no better domain fits.
- `environments/` — self-contained flake entrypoints; see `environments/README.md`.
  - `environments/default/` — default environment composition, Home Manager wiring, and default-only shell behavior.
- `scripts/` — repository maintenance commands; see `scripts/README.md` before adding/changing scripts.
- `.agents/skills/` — agent skill instructions for specialized repository workflows.
- `.beads/` — persistent issue/task tracker storage; do not edit manually unless working on tracker internals.
- `.pi/` — local Pi coding-agent configuration/extensions.
