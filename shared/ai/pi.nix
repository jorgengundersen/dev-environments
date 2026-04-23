{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.pi = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.pi
        ];
      };
    };

  flake.homeModules.pi = _: {
    home.sessionVariables = {
      PI_CODING_AGENT_DIR = "$XDG_STATE_HOME/pi/agent";
      PI_PACKAGE_DIR = "$XDG_STATE_HOME/pi/packages";
    };
  };
}
