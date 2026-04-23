{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.claude = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.claude-code
        ];
      };
    };

  flake.homeModules.claude = _: {
    home.sessionVariables = {
      CLAUDE_CONFIG_DIR = "$XDG_STATE_HOME/claude";
    };
  };
}
