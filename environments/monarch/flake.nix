{
  description = "Monarch Alpha development environment";

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
      ];

      perSystem =
        {
          config,
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${system};

          formatter = pkgs.nixfmt;

          apps.monarch-session-prepare = {
            type = "app";
            meta.description = "Prepare Home Manager for Monarch Alpha sessions";
            program = toString (
              pkgs.writeShellScript "monarch-session-prepare" ''
                set -euo pipefail

                log() {
                  printf 'monarch-session-prepare: %s\n' "$*" >&2
                }

                if [ "''${MONARCH_SKIP_HOME_MANAGER:-0}" = "1" ]; then
                  log "MONARCH_SKIP_HOME_MANAGER=1; skipping Home Manager activation"
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
                  log "USER is unset and could not be resolved"
                  log "Set USER, ensure 'id -un' works, or disable with MONARCH_SKIP_HOME_MANAGER=1"
                  exit 1
                fi

                export USER="$user"

                if [ -z "$home" ]; then
                  log "HOME is unset; cannot resolve Home Manager target"
                  log "Set HOME or disable with MONARCH_SKIP_HOME_MANAGER=1"
                  exit 1
                fi

                if [ ! -d "$home" ]; then
                  log "HOME does not exist or is not a directory: $home"
                  log "Create HOME or disable with MONARCH_SKIP_HOME_MANAGER=1"
                  exit 1
                fi

                export HOME="$home"

                if [ -n "''${MONARCH_HOME_MANAGER_TARGET:-}" ]; then
                  target="$MONARCH_HOME_MANAGER_TARGET"
                else
                  case "${system}" in
                    aarch64-linux)
                      target="$user@aarch64"
                      ;;
                    *)
                      target="default"
                      ;;
                  esac
                fi
                flake_ref="''${MONARCH_HOME_MANAGER_FLAKE:-}"
                backup_ext="''${MONARCH_HOME_MANAGER_BACKUP_EXT:-monarch-backup}"
                tmp_flake_root=""

                cleanup() {
                  if [ -n "$tmp_flake_root" ] && [ -d "$tmp_flake_root" ]; then
                    ${pkgs.coreutils}/bin/chmod -R u+w "$tmp_flake_root" >/dev/null 2>&1 || true
                    ${pkgs.coreutils}/bin/rm -rf "$tmp_flake_root" >/dev/null 2>&1 || true
                  fi
                }
                trap cleanup EXIT

                if [ -z "$flake_ref" ]; then
                  source_root="${builtins.dirOf (builtins.dirOf inputs.self.outPath)}"
                  tmp_flake_root="$(${pkgs.coreutils}/bin/mktemp -d)"
                  ${pkgs.coreutils}/bin/cp -R "$source_root/." "$tmp_flake_root/"
                  (
                    cd "$tmp_flake_root"
                    ${pkgs.git}/bin/git init -q
                    ${pkgs.git}/bin/git add -A
                  )
                  flake_ref="git+file://$tmp_flake_root?dir=environments/monarch"
                fi

                build_args=(
                  --extra-experimental-features "nix-command flakes"
                  build
                  --impure
                  --no-link
                  --print-out-paths
                )

                case "''${MONARCH_HOME_MANAGER_REFRESH:-0}" in
                  1|true|TRUE|yes|YES|on|ON)
                    build_args+=(--refresh)
                    ;;
                esac

                if [ "$backup_ext" = "none" ]; then
                  unset HOME_MANAGER_BACKUP_EXT
                else
                  export HOME_MANAGER_BACKUP_EXT="$backup_ext"
                fi

                log "building Home Manager activation package: $flake_ref#homeConfigurations.$target.activationPackage"
                if ! activation_path="$(${pkgs.nix}/bin/nix "''${build_args[@]}" "$flake_ref#homeConfigurations.$target.activationPackage")"; then
                  log "failed to build Home Manager activation package"
                  log "Check MONARCH_HOME_MANAGER_FLAKE/MONARCH_HOME_MANAGER_TARGET or disable with MONARCH_SKIP_HOME_MANAGER=1"
                  exit 1
                fi

                if [ -z "$activation_path" ] || [ ! -x "$activation_path/activate" ]; then
                  log "activation package did not contain an executable activate script: $activation_path"
                  exit 1
                fi

                log "running activation script: $activation_path/activate"
                if ! "$activation_path/activate"; then
                  log "Home Manager activation failed"
                  log "Try MONARCH_HOME_MANAGER_BACKUP_EXT=<ext> (default: monarch-backup), MONARCH_HOME_MANAGER_BACKUP_EXT=none, or MONARCH_SKIP_HOME_MANAGER=1"
                  exit 1
                fi

                log "Home Manager activation completed"
              ''
            );
          };

          checks.monarch-session-prepare-target-selection =
            pkgs.runCommand "monarch-session-prepare-target-selection" { }
              ''
                script="${config.apps.monarch-session-prepare.program}"

                ${pkgs.gnugrep}/bin/grep -F 'target="$MONARCH_HOME_MANAGER_TARGET"' "$script" >/dev/null
                ${pkgs.gnugrep}/bin/grep -F 'case "${system}" in' "$script" >/dev/null

                case "${system}" in
                  aarch64-linux)
                    ${pkgs.gnugrep}/bin/grep -F 'target="$user@aarch64"' "$script" >/dev/null
                    ;;
                  x86_64-linux)
                    ${pkgs.gnugrep}/bin/grep -F 'target="default"' "$script" >/dev/null
                    ;;
                esac

                touch "$out"
              '';
        };
    };
}
