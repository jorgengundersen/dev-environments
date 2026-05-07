_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.gh = pkgs.mkShell {
        packages = [ pkgs.gh ];
        shellHook = ''
          if [ -n "''${HOME:-}" ]; then
            : "''${XDG_STATE_HOME:=$HOME/.local/state}"
          fi

          : "''${GH_CONFIG_DIR:=$XDG_STATE_HOME/gh}"

          export XDG_STATE_HOME GH_CONFIG_DIR

          if [ -n "$GH_CONFIG_DIR" ] && [ ! -d "$GH_CONFIG_DIR" ]; then
            mkdir -p "$GH_CONFIG_DIR" >/dev/null 2>&1 || true
          fi
        '';
      };
    };

  flake.homeModules.gh =
    { config, lib, ... }:
    {
      programs.gh.enable = true;

      home.sessionVariables = {
        GH_CONFIG_DIR = "${config.xdg.stateHome}/gh";
      };

      home.activation.createGhConfigDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${config.xdg.stateHome}/gh"
      '';
    };
}
