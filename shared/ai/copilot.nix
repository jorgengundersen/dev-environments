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
}
