_:
let
  defaultProfile = [
    "core"
    "bash"
    "tmux"
    "prompt"
    "python"
    "codex"
    "pi"
    "dolt"
    "beads"
    "git"
    "gh"
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

            packages = with pkgs; [
              bashInteractive
              coreutils
              findutils
              gnugrep
              gnused
              gnutar
              gzip
              cacert
              procps
              util-linux
              openssh
            ];

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
                : "''${XDG_DATA_HOME:=$HOME/.local/share}"
                : "''${XDG_CACHE_HOME:=$HOME/.cache}"
                : "''${XDG_STATE_HOME:=$HOME/.local/state}"
              fi

              if [ -n "''${XDG_STATE_HOME:-}" ]; then
                : "''${PI_CODING_AGENT_DIR:=$XDG_STATE_HOME/pi/agent}"
                : "''${CODEX_HOME:=$XDG_STATE_HOME/codex}"
                : "''${GH_CONFIG_DIR:=$XDG_STATE_HOME/gh}"
                : "''${CLAUDE_CONFIG_DIR:=$XDG_STATE_HOME/claude}"
              fi

              : "''${EDITOR:=vi}"
              : "''${VISUAL:=$EDITOR}"

              export XDG_CONFIG_HOME XDG_DATA_HOME XDG_CACHE_HOME XDG_STATE_HOME
              export PI_CODING_AGENT_DIR CODEX_HOME GH_CONFIG_DIR CLAUDE_CONFIG_DIR
              export EDITOR VISUAL

              for state_dir in \
                "''${XDG_CONFIG_HOME:-}" \
                "''${XDG_DATA_HOME:-}" \
                "''${XDG_CACHE_HOME:-}" \
                "''${XDG_STATE_HOME:-}" \
                "''${PI_CODING_AGENT_DIR:-}" \
                "''${CODEX_HOME:-}" \
                "''${GH_CONFIG_DIR:-}" \
                "''${CLAUDE_CONFIG_DIR:-}"
              do
                if [ -n "$state_dir" ] && [ ! -d "$state_dir" ]; then
                  mkdir -p "$state_dir" >/dev/null 2>&1 || true
                fi
              done
            '';
          }
        else
          throw "monarch defaultProfile references missing devShells: ${builtins.concatStringsSep ", " missingShells}";
    };
}
