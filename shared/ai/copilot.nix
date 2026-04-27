{ inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      devShells.copilot = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.copilot-cli
        ];
        shellHook = ''
          if [ -n "''${HOME:-}" ]; then
            : "''${XDG_STATE_HOME:=$HOME/.local/state}"
            : "''${XDG_CACHE_HOME:=$HOME/.cache}"
          fi

          : "''${COPILOT_HOME:=$XDG_STATE_HOME/copilot}"
          : "''${COPILOT_CACHE_HOME:=$XDG_CACHE_HOME/copilot}"

          export XDG_STATE_HOME XDG_CACHE_HOME
          export COPILOT_HOME COPILOT_CACHE_HOME

          if [ -n "$COPILOT_HOME" ] && [ ! -d "$COPILOT_HOME" ]; then
            mkdir -p "$COPILOT_HOME" >/dev/null 2>&1 || true
          fi

          if [ -n "$COPILOT_CACHE_HOME" ] && [ ! -d "$COPILOT_CACHE_HOME" ]; then
            mkdir -p "$COPILOT_CACHE_HOME" >/dev/null 2>&1 || true
          fi
        '';
      };
    };

  flake.homeModules.copilot = _: {
    home.sessionVariables = {
      COPILOT_HOME = "$XDG_STATE_HOME/copilot";
      COPILOT_CACHE_HOME = "$XDG_CACHE_HOME/copilot";
    };
  };
}
