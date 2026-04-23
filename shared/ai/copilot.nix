{ inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      devShells.copilot = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.copilot-cli
        ];
      };
    };

  flake.homeModules.copilot = _: {
    home.sessionVariables = {
      COPILOT_HOME = "$XDG_STATE_HOME/copilot";
      COPILOT_CACHE_HOME = "$XDG_CACHE_HOME/copilot";
    };
  };
}
