# dev-environments

Composable, reproducible development environments using Nix flakes, flake-parts, import-tree, and Home Manager following the dendritic pattern.

## Quick Start

```bash
# Enter the default environment (all tools)
nix develop

# Enter a specific environment
nix develop .#minimal   # core + bash + starship
nix develop .#go        # Go toolchain
nix develop .#rust      # Rust toolchain
nix develop .#node      # Node.js
nix develop .#python    # Python + uv
nix develop .#claude    # Claude Code

# Use from another project (remote flake reference)
nix develop github:jorgengundersen/dev-environments#go
```

### With direnv

Add to your project's `.envrc`:

```bash
use flake github:jorgengundersen/dev-environments
# or for a specific shell:
use flake github:jorgengundersen/dev-environments#go
```

## Environments

| Shell | Description |
|-------|-------------|
| `default` | All tools combined |
| `minimal` | Core utilities + bash + starship prompt |

## Dev Shells

### Core

| Shell | Tools |
|-------|-------|
| `core` | git, gh, jq, yq, ripgrep, make, curl, wget, tree, unzip |
| `bash` | bash-completion |
| `prompt` | starship |
| `fzf` | fzf |

### Languages

| Shell | Tools |
|-------|-------|
| `go` | go, gopls, golangci-lint |
| `rust` | rustc, cargo, rustfmt, clippy, rust-analyzer |
| `node` | nodejs |
| `python` | python3, uv |
| `bun` | bun |

### AI

| Shell | Tools |
|-------|-------|
| `claude` | claude-code (via llm-agents.nix) |
| `copilot` | gh, copilot-cli (via llm-agents.nix) |

### Data

| Shell | Tools |
|-------|-------|
| `beads` | beads (via llm-agents.nix) |
| `dolt` | dolt |

### Editors

| Shell | Tools |
|-------|-------|
| `neovim` | neovim, tree-sitter, nil, gopls, rust-analyzer |

### Quality

| Shell | Tools |
|-------|-------|
| `linters` | shellcheck, mdformat, lefthook, bats, hadolint (Linux) |

### Git

| Shell | Tools |
|-------|-------|
| `git` | git, gh, delta |

### Utils

| Shell | Tools |
|-------|-------|
| `glow` | glow |
| `afk` | afk (via jorgengundersen/afk) |
| `opencode` | opencode (via llm-agents.nix) |

## Home Manager

A standalone Home Manager configuration is available for persistent dotfile management:

```bash
# Build the home configuration
nix build .#homeConfigurations.default.activationPackage

# Activate
./result/activate
```

Home modules configure: bash (aliases, completion), starship prompt, fzf (keybindings), git (delta, aliases), and neovim (treesitter, LSP).

## Adding a New Tool

Create a single `.nix` file anywhere in the repo. import-tree auto-discovers it — no registry to update.

```nix
# tools/mytool.nix
_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.mytool = pkgs.mkShell {
        packages = [ pkgs.mytool ];
      };
    };
}
```

The new shell is immediately available via `nix develop .#mytool`. It's also automatically included in the `default` shell.

To add Home Manager configuration, define a `homeModules` entry in the same file:

```nix
{ config, lib, ... }:
{
  options.flake.homeModules = lib.mkOption {
    type = lib.types.attrsOf lib.types.unspecified;
    default = { };
  };

  config.flake.homeModules.mytool = {
    programs.mytool.enable = true;
  };

  perSystem =
    { pkgs, ... }:
    {
      devShells.mytool = pkgs.mkShell {
        packages = [ pkgs.mytool ];
      };
    };
}
```

## Architecture

This repo follows the **dendritic pattern** — each `.nix` file is a self-contained flake-parts module organized by feature. Files are freely movable and auto-discovered by import-tree. See `specs/spec.md` for the full architecture specification.
