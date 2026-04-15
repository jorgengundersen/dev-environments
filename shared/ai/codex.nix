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
}
