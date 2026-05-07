_:
let
  defaultProfile = [
    "core"
    "bash"
    "tmux"
    "prompt"
    "fzf"
    "go"
    "rust"
    "node"
    "python"
    "bun"
    "neovim"
    "claude"
    "codex"
    "copilot"
    "pi"
    "dolt"
    "beads"
    "linters"
    "git"
    "gh"
    "just"
    "glow"
    "typst"
    "mermaid"
    "afk"
    "opencode"
  ];
in
{
  perSystem =
    { self', pkgs, ... }:
    let
      missingShells = builtins.filter (name: !(builtins.hasAttr name self'.devShells)) defaultProfile;
    in
    {
      devShells.default =
        if missingShells == [ ] then
          pkgs.mkShell {
            inputsFrom = builtins.map (name: self'.devShells.${name}) defaultProfile;
            NIX_BUILD_CORES = "4";
            CARGO_BUILD_JOBS = "4";
            NIX_CONFIG = ''
              cores = 4
              max-jobs = 1
            '';
            shellHook = ''
              hm_user="''${USER:-}"
              if [ -z "$hm_user" ] && command -v id >/dev/null 2>&1; then
                hm_user="$(id -un 2>/dev/null || true)"
              fi

              for hm_session_vars in \
                "''${HOME:-}/.nix-profile/etc/profile.d/hm-session-vars.sh" \
                "''${HOME:-}/.local/state/nix/profile/etc/profile.d/hm-session-vars.sh" \
                "''${HOME:-}/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh" \
                "/etc/profiles/per-user/$hm_user/etc/profile.d/hm-session-vars.sh"
              do
                if [ -f "$hm_session_vars" ]; then
                  # shellcheck disable=SC1090
                  . "$hm_session_vars"
                  break
                fi
              done

              if [ -n "''${HOME:-}" ]; then
                : "''${XDG_CONFIG_HOME:=$HOME/.config}"
                : "''${XDG_CACHE_HOME:=$HOME/.cache}"
                : "''${XDG_DATA_HOME:=$HOME/.local/share}"
                : "''${XDG_STATE_HOME:=$HOME/.local/state}"
              fi

              : "''${EDITOR:=nvim}"
              : "''${VISUAL:=nvim}"
              : "''${CODEX_HOME:=$XDG_STATE_HOME/codex}"
              : "''${CLAUDE_CONFIG_DIR:=$XDG_STATE_HOME/claude}"
              : "''${COPILOT_HOME:=$XDG_STATE_HOME/copilot}"
              : "''${COPILOT_CACHE_HOME:=$XDG_CACHE_HOME/copilot}"
              : "''${PI_CODING_AGENT_DIR:=$XDG_STATE_HOME/pi/agent}"
              : "''${GH_CONFIG_DIR:=$XDG_STATE_HOME/gh}"

              export XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME XDG_STATE_HOME
              export EDITOR VISUAL
              export CODEX_HOME CLAUDE_CONFIG_DIR COPILOT_HOME COPILOT_CACHE_HOME
              export PI_CODING_AGENT_DIR GH_CONFIG_DIR

              for state_dir in \
                "$XDG_CONFIG_HOME" \
                "$XDG_CACHE_HOME" \
                "$XDG_DATA_HOME" \
                "$XDG_STATE_HOME" \
                "$CODEX_HOME" \
                "$CLAUDE_CONFIG_DIR" \
                "$COPILOT_HOME" \
                "$COPILOT_CACHE_HOME" \
                "$PI_CODING_AGENT_DIR" \
                "$GH_CONFIG_DIR"
              do
                if [ -n "$state_dir" ] && [ ! -d "$state_dir" ]; then
                  mkdir -p "$state_dir" >/dev/null 2>&1 || true
                fi
              done
            '';
          }
        else
          throw "defaultProfile references missing devShells: ${builtins.concatStringsSep ", " missingShells}";
    };
}
