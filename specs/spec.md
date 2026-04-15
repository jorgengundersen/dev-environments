# Dev Environments Specification

## Purpose

This repository defines composable, reproducible development environments using Nix flakes, flake-parts, and Home Manager, following the **dendritic pattern**. It replaces the dependency management layer previously handled by multi-stage Docker images in `jorgengundersen/devenv`.

**This repo is not a Docker replacement.** It manages *what tools and configurations* are available. A separate orchestration tool (to be built) manages *how environments run* (Docker containers, volumes, networking, SSH). That tool will reference environments defined here.

## Goals

1. **Reproducibility** — Pinned dependencies via `flake.lock`, identical environments across machines and containers
2. **Composability** — Mix and match tool groups to create purpose-built environments
3. **Maintainability** — Adding, updating, or removing a tool is a single-file change; each file is self-contained and freely movable
4. **Reusability** — Environments are consumable as flake references (`nix develop github:jorgengundersen/dev-environments#<name>`)
5. **Declarative configuration** — Dotfiles and tool settings managed by Home Manager, not manually mounted bind mounts

## Non-Goals

- Container orchestration (Docker build/run/volumes) — handled by the separate tool
- OS-level configuration (NixOS modules) — environments target user-space only
- Replacing project-specific dependencies — this manages the *developer toolbox*, not per-project deps

## Architecture

### The Dendritic Pattern

This repo follows the **dendritic pattern** — an aspect-oriented approach to Nix configuration where files are organized by **feature**, not by configuration class.

**Key principles:**

- Every `.nix` file (except `flake.nix`) is a **flake-parts module** of the same top-level configuration
- Each file is **self-contained**: it declares packages, Home Manager config, shell hooks, and checks for a single feature/aspect
- Files are **freely movable** — rename, split, or reorganize without updating a central registry
- **import-tree** auto-discovers all modules in the directory tree — no manual import lists

**Why dendritic over traditional modules + environments?**

In a traditional layout, adding "Go support" requires touching `modules/languages/go.nix` for packages, `home/go.nix` for config, and `environments/default.nix` to wire it in. In the dendritic pattern, `go.nix` is one file that handles all of this. The feature is the organizing unit, not the config class.

### Flake Entry Point

The `flake.nix` at the repository root is minimal. It declares inputs and delegates everything to flake-parts + import-tree:

```nix
{
  description = "Composable dev environments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.import-tree.flakeModule ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
    };
}
```

`flake.lock` pins all inputs to exact revisions. This file is committed to git and is the source of truth for reproducibility.

### Directory Structure

```
dev-environments/
  flake.nix                   # Entry point — minimal, delegates to flake-parts
  flake.lock                  # Pinned inputs

  core.nix                    # Always-included base tools (git, jq, ripgrep, etc.)

  languages/
    go.nix                    # Go toolchain + env vars + config
    rust.nix                  # Rust toolchain
    node.nix                  # Node.js
    python.nix                # Python + uv
    bun.nix                   # Bun runtime

  editors/
    neovim.nix                # Neovim + tree-sitter + LSP + Home Manager config

  ai/
    claude.nix                # claude-code
    copilot.nix               # copilot-cli

  data/
    dolt.nix                  # Dolt
    beads.nix                 # Beads issue tracker

  quality/
    linters.nix               # shellcheck, hadolint, mdformat, lefthook, bats

  shell/
    prompt.nix                # Starship prompt + Home Manager config
    bash.nix                  # bashrc, aliases, completions
    fzf.nix                   # fzf integration and key bindings

  git/
    config.nix                # gitconfig, aliases, delta

  utils/
    glow.nix                  # Glow markdown viewer
    opencode.nix              # OpenCode
    afk.nix                   # AFK

  environments/
    default.nix               # Full environment — composes all aspects
    minimal.nix               # Core + shell only
```

Each subdirectory groups related aspects but imposes no structural meaning — it's purely for human navigation. import-tree treats every `.nix` file equally regardless of depth.

### Module Contract

Every `.nix` file (except `flake.nix`) is a flake-parts module. Each module can contribute to any flake output — dev shells, Home Manager config, checks — for its aspect:

```nix
# languages/go.nix
{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    # Packages for this aspect
    devShells.go = pkgs.mkShell {
      packages = with pkgs; [ go gopls golangci-lint ];
      env = {
        GOPATH = "$HOME/go";
      };
    };

    # Checks for this aspect
    checks.go-vet = pkgs.runCommand "go-vet" { } ''
      # validation logic
      touch $out
    '';
  };
}
```

For aspects that include Home Manager configuration:

```nix
# git/config.nix
{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    # Packages
    devShells.git = pkgs.mkShell {
      packages = with pkgs; [ git gh delta ];
    };
  };

  # Home Manager config for this aspect
  flake.homeModules.git = { pkgs, ... }: {
    programs.git = {
      enable = true;
      delta.enable = true;
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };
}
```

### Environments

Environments compose aspects. Aspect shells are still defined in their own files (`devShells.go`, `devShells.core`, etc.), and environment entrypoints (`default`, `minimal`, etc.) select from those shells using named profiles.

`environments/profiles.json` defines profile membership in one place:

```json
{
  "default": ["core", "bash", "prompt", "go", "rust", "node"],
  "minimal": ["core", "bash", "prompt"]
}
```

Each environment entrypoint maps profile names to actual shells:

```nix
# environments/default.nix
_:
let
  profiles = builtins.fromJSON (builtins.readFile ./profiles.json);
in
{
  perSystem = { pkgs, self', ... }: {
    devShells.default = pkgs.mkShell {
      inputsFrom = builtins.map (name: self'.devShells.${name}) profiles.default;
    };
  };
}
```

```nix
# environments/minimal.nix
_:
let
  profiles = builtins.fromJSON (builtins.readFile ./profiles.json);
in
{
  perSystem = { pkgs, self', ... }: {
    devShells.minimal = pkgs.mkShell {
      inputsFrom = builtins.map (name: self'.devShells.${name}) profiles.minimal;
    };
  };
}
```

This keeps a single root flake/lockfile while making environment composition explicit and decoupled from automatic "include everything" behavior.

### Build Behavior and Entrypoint Isolation

When activating a specific shell (for example `nix develop .#minimal`), Nix realizes only that shell's dependency closure. It does **not** build other shell entrypoints such as `default` unless they are explicitly referenced.

In other words:

- `nix develop` builds `devShells.default`
- `nix develop .#minimal` builds `devShells.minimal`
- `nix develop .#go` builds `devShells.go`

This provides practical entrypoint-level build isolation for container workflows.

However, module loading/evaluation is broader than realization:

- The flake/module graph is still evaluated to resolve outputs
- A broken unrelated module can still fail evaluation even if its shell is not selected

Therefore, all aspect files should remain evaluation-safe across supported platforms. Platform-specific packages must be guarded with conditional inclusion (`lib.optionals`, `lib.mkIf`, etc.) so selecting one environment does not fail because of another aspect's unsupported package.

### Home Manager

Home Manager handles user-level configuration that would otherwise be bind-mounted dotfiles. In the dendritic pattern, Home Manager config lives **alongside the packages it configures**, not in a separate directory.

For example, `editors/neovim.nix` defines both the neovim package for the dev shell and the Home Manager module for neovim configuration. `shell/prompt.nix` defines both starship as a package and its Home Manager theme config.

Home Manager runs in **standalone mode** (not as a NixOS module), making it compatible with any Linux host including Docker containers.

The flake exposes `homeConfigurations` that compose all `homeModules` defined by aspect files. The orchestration tool can activate these inside containers via `home-manager switch`.

## Tool Inventory

Tools from the current devenv, mapped to their aspect file:

| Tool | Nixpkgs | Aspect | Notes |
|------|---------|--------|-------|
| git | yes | core | |
| gh (GitHub CLI) | yes | core | |
| jq | yes | core | |
| yq | yes | core | |
| ripgrep | yes | core | |
| fzf | yes | shell/fzf | With Home Manager key bindings |
| make | yes | core | |
| go | yes | languages/go | |
| cargo/rustc | yes | languages/rust | |
| nodejs/fnm | yes | languages/node | Use nix-managed node versions instead of fnm |
| python/uv | yes | languages/python | |
| bun | yes | languages/bun | |
| neovim | yes | editors/neovim | With Home Manager plugin/LSP config |
| tree-sitter | yes | editors/neovim | Bundled with neovim aspect |
| claude-code | no | ai/claude | npm-installed, needs custom derivation or shell hook |
| copilot-cli | no | ai/copilot | gh extension, installed via shell hook |
| dolt | yes | data/dolt | |
| beads | no | data/beads | Custom build or fetchurl |
| shellcheck | yes | quality/linters | |
| hadolint | yes | quality/linters | |
| mdformat | yes | quality/linters | |
| lefthook | yes | quality/linters | |
| bats | yes | quality/linters | |
| starship | yes | shell/prompt | With Home Manager theme config |
| glow | yes | utils/glow | |
| opencode | no | utils/opencode | May need custom derivation |
| afk | no | utils/afk | May need custom derivation |

Tools marked "no" under Nixpkgs will need one of:
- A custom Nix derivation (preferred)
- Installation via shell hook (e.g., `npm install -g`)
- A third-party flake input

## Naming

The default environment is named `default` (nix convention). The word "devenv" is not used as an environment name to avoid collision with [cachix/devenv](https://devenv.sh/).

The repository itself is `dev-environments`. When referring to the primary environment in documentation, use "default environment" or just "default".

## System Support

Supported systems:

| System | Context |
|--------|---------|
| `x86_64-linux` | WSL2 (Ubuntu), Docker containers |
| `aarch64-linux` | Docker containers (ARM hosts) |
| `x86_64-darwin` | Intel Mac |
| `aarch64-darwin` | Apple Silicon Mac |

All four systems are first-class targets. flake-parts handles multi-system output generation via the `systems` list — no per-platform duplication.

Aspect modules are system-agnostic; they use `perSystem` and reference `pkgs.<name>`, letting nixpkgs resolve the correct derivation for the active system. For tools that require custom derivations (claude-code, beads, etc.), those derivations must also support all four systems, or be conditionally included with `lib.optionals` when a platform isn't supported.

**Platform-specific notes:**
- macOS does not use Docker for the environment itself — `nix develop` runs natively
- Some tools (e.g., hadolint) may have limited darwin support — these are handled gracefully with conditional inclusion rather than failing the entire environment

## Integration with Docker

The orchestration tool (separate repo, to be built) will:

1. Build a minimal base Docker image with Nix installed
2. Reference this flake to `nix develop` or `nix build` the desired environment
3. Optionally run `home-manager switch` for dotfile configuration
4. Handle everything else Docker-side: volumes, networking, SSH forwarding, user setup

This clean separation means this repo never contains Dockerfiles, and the orchestration tool never manages tool versions.

## Workflow

**Adding a tool:**
1. Create or edit the appropriate aspect file — add packages, Home Manager config, and checks in one place
2. The tool shell is automatically discovered by import-tree; no need to update `flake.nix`
3. Add the shell name to one or more profiles in `environments/profiles.json` if it should be included in composed environments like `default` or `minimal`
4. `nix flake check` to validate
5. Commit

**Creating a new environment:**
1. Create a file in `environments/` that composes aspects via `inputsFrom`
2. It's auto-discovered — no registration in `flake.nix` needed
3. Use with `nix develop .#<name>`

**Splitting a growing aspect:**
1. Break the file into a subdirectory with multiple files (e.g., `quality/linters.nix` becomes `quality/shellcheck.nix`, `quality/hadolint.nix`, etc.)
2. import-tree discovers the new files automatically
3. No other files need to change

**Updating dependencies:**
1. `nix flake update` to bump all inputs, or `nix flake update <input>` for a specific one
2. Test with `nix develop`
3. Commit the updated `flake.lock`
