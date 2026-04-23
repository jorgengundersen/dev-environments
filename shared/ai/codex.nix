{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.codex = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.codex
        ];
      };
    };

  flake.homeModules.codex = _: {
    home.sessionVariables = {
      CODEX_HOME = "$XDG_STATE_HOME/codex";
    };
  };
}
