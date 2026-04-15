---
name: add-shared-resource
description: Place new shared tools in the right domain, create a new shared domain when needed, and prevent utils from becoming a junkyard. Use when user asks to add a package/tool/module under shared/. Create a placement plan first, then implement and validate.
---

# add-shared-resource

Add tool/module to `shared/` with strict domain triage.

## Flow

1. **Classify** tool domain before edits.
2. **Plan** target path + required file/doc updates.
3. **Implement** module move/add and composition updates.
4. **Validate** with `nix flake check ./environments/default`.
5. **Report** why placement is correct.

## Domain triage

Use first match:

Reference domain definitions in `shared/README.md`.

1. `shared/ai/` — coding/agent/LLM CLIs.
2. `shared/docs/` — docs, diagrams, publishing, rendering.
3. `shared/languages/` — language runtimes/toolchains.
4. `shared/quality/` — lint/test/scan/format quality tooling.
5. `shared/data/` — database/data-local tooling.
6. `shared/git/` — git-centric workflows.
7. `shared/shell/` — shell UX/runtime behavior.
8. `shared/editors/` — editor toolchains/config.
9. `shared/utils/` — only if cross-domain and no better fit.

## Utils guardrail

`shared/utils/` allowed only with explicit justification:

- tool is general-purpose across multiple domains,
- no existing domain is a natural home,
- creating a new domain is not yet warranted.

If any condition fails, do **not** use `utils`.

## When to create a new domain

Create `shared/<domain>/` when at least one is true:

- 2+ related tools exist or are planned,
- current placement would overload `utils`,
- domain needs first-class indexing in `shared/README.md`.

If created, also update `shared/README.md`.

## Required updates

After placement decision, update all relevant items:

- module file path (`shared/<domain>/<tool>.nix`),
- `environments/default/default.nix` profile list (if requested),
- `shared/README.md` domain index,
- `specs/spec.md` shared-domain list if domain set changed.

## Anti-patterns

1. Dumping unknown tools into `utils` without triage.
2. Mixing AI/docs/language tooling into `utils`.
3. Adding module file but forgetting composition updates.
4. Creating new domain without shared index/spec updates.

## Hard rules

- Always present placement rationale.
- Always run validation check after changes.
- Never store secrets or user-specific paths in shared modules.
- Keep module names aligned to `devShells.<name>`.
