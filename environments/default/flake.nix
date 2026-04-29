{
  description = "Default development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    afk = {
      url = "github:jorgengundersen/afk";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        (inputs.import-tree.matchNot ".*flake.*" ../../shared)
        ./home-modules.nix
        ./home.nix
        ./default.nix
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, system, ... }:
        {
          _module.args.pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${system};

          formatter = pkgs.nixfmt;

          apps.havn-session-prepare = {
            type = "app";
            meta.description = "Prepare Home Manager for havn sessions";
            program = toString (
              pkgs.writeShellScript "havn-session-prepare" ''
                set -euo pipefail

                if [ "''${HAVN_SKIP_HOME_MANAGER:-0}" = "1" ]; then
                  exit 0
                fi

                user="''${USER:-}"
                home="''${HOME:-}"

                if [ -z "$user" ] && command -v id >/dev/null 2>&1; then
                  user="$(id -un 2>/dev/null || true)"
                fi

                if [ -z "$user" ] && command -v whoami >/dev/null 2>&1; then
                  user="$(whoami 2>/dev/null || true)"
                fi

                if [ -z "$user" ]; then
                  echo "havn-session-prepare: USER is unset; cannot resolve Home Manager target" >&2
                  echo "Set USER, ensure 'id -un' works, or disable with HAVN_SKIP_HOME_MANAGER=1" >&2
                  exit 1
                fi

                export USER="$user"

                if [ -z "$home" ]; then
                  echo "havn-session-prepare: HOME is unset; cannot resolve Home Manager target" >&2
                  echo "Set HOME or disable with HAVN_SKIP_HOME_MANAGER=1" >&2
                  exit 1
                fi

                target="''${HAVN_HOME_MANAGER_TARGET:-default}"
                default_flake_ref="devenv"
                flake_ref="''${HAVN_HOME_MANAGER_FLAKE:-$default_flake_ref}"
                backup_ext="''${HAVN_HOME_MANAGER_BACKUP_EXT:-havn-backup}"
                refresh_flag=""

                case "''${HAVN_HOME_MANAGER_REFRESH:-0}" in
                  1|true|TRUE|yes|YES|on|ON)
                    refresh_flag="--refresh"
                    ;;
                esac

                if [ "$backup_ext" = "none" ]; then
                  unset HOME_MANAGER_BACKUP_EXT
                else
                  export HOME_MANAGER_BACKUP_EXT="$backup_ext"
                fi

                if ! activation_path="$(${pkgs.nix}/bin/nix --extra-experimental-features 'nix-command flakes' build ''${refresh_flag:+$refresh_flag} --impure --no-link --print-out-paths "$flake_ref#homeConfigurations.$target.activationPackage")"; then
                  echo "havn-session-prepare: failed to build Home Manager activation package" >&2
                  echo "Check HAVN_HOME_MANAGER_FLAKE/HAVN_HOME_MANAGER_TARGET or disable with HAVN_SKIP_HOME_MANAGER=1" >&2
                  exit 1
                fi

                if ! "$activation_path/activate"; then
                  echo "havn-session-prepare: Home Manager activation failed" >&2
                  echo "Try setting HAVN_HOME_MANAGER_BACKUP_EXT=<ext> (default: havn-backup) or disable with HAVN_SKIP_HOME_MANAGER=1" >&2
                  exit 1
                fi
              ''
            );
          };
        };
    };
}
