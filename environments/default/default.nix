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
            '';
          }
        else
          throw "defaultProfile references missing devShells: ${builtins.concatStringsSep ", " missingShells}";
    };
}
