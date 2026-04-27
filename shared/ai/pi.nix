{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.pi = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.pi
        ];
        shellHook = ''
          if [ -n "''${HOME:-}" ]; then
            : "''${XDG_STATE_HOME:=$HOME/.local/state}"
          fi

          : "''${PI_CODING_AGENT_DIR:=$XDG_STATE_HOME/pi/agent}"

          export XDG_STATE_HOME
          export PI_CODING_AGENT_DIR

          if [ -n "$PI_CODING_AGENT_DIR" ] && [ ! -d "$PI_CODING_AGENT_DIR" ]; then
            mkdir -p "$PI_CODING_AGENT_DIR" >/dev/null 2>&1 || true
          fi
        '';
      };
    };

  flake.homeModules.pi = _: {
    home.sessionVariables = {
      PI_CODING_AGENT_DIR = "$XDG_STATE_HOME/pi/agent";
    };
  };
}
