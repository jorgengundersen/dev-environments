# pi project-local extensions

## `block-commands.ts`

Auto-loaded by pi from `.pi/extensions/block-commands.ts`.

If you want it in every repo, copy it to `~/.pi/agent/extensions/block-commands.ts`.

What it does:

- blocks **all `gh` commands by default**, except this small allowlist:
  - `gh --version`
  - `gh help`
  - `gh auth status`
  - `gh repo view`
  - `gh issue list`
  - `gh issue view`
  - `gh pr list`
  - `gh pr view`
  - `gh release list`
- allows `git` generally, but blocks force-push variants:
  - `git push -f`
  - `git push --force`
  - `git push --force-with-lease`
  - `git push --force-if-includes`
  - `git push ... +<refspec>`
- applies to both:
  - LLM `bash` tool calls
  - user `!` / `!!` shell commands inside pi

## Reusing or extending it

Edit `.pi/extensions/block-commands.ts` and update `commandPolicies`.

The file is structured around:

- `defaultBlock` policies for commands that should be denied unless explicitly allowed
- `defaultAllow` policies for commands that should work normally except for specific blocked forms

Good fit examples:

- block `kubectl` except `get`/`describe`
- block `terraform` except `plan`
- block destructive `docker` subcommands

## Notes

This is a workflow guard inside pi, not a full sandbox.
Other trusted pi extensions can still execute commands via extension APIs.
