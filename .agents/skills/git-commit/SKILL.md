---
name: git-commit
description: Make scope-based git commits. Use when committing changes.
---

# git-commit

Use scope-based commits:

```text
<scope>: <summary>

<body>

<footer>
```

Rules:

- No Conventional Commit prefixes (`feat:`, `fix:`, etc.).
- Scope is the main area changed: `docs`, `specs`, `docker`, `scripts`, `env`, `realm`.
- Keep summary imperative and concise.
- Body is optional; use it for context, rationale, or notable details.
- Footer is optional; use it for ticket/issue references or other metadata.
- Run relevant checks before commit.
- Stage only intended files.
- Verify clean/expected status after commit.

Examples:

```text
docker: add dev-environments mount
scripts: require dev-environments checkout
docs: clarify realm setup
```

```text
realm: require local dev-environments checkout

Keep the Nix flake path local to avoid repeated remote fetches during realm startup.

Refs: bd-123
```
