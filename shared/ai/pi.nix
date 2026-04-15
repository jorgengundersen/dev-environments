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
}
