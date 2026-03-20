{ inputs, ... }:
{
  perSystem =
    { system, pkgs, ... }:
    {
      devShells.copilot = pkgs.mkShell {
        packages = [
          pkgs.gh
          inputs.llm-agents.packages.${system}.copilot-cli
        ];
      };
    };
}
