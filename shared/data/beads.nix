{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.beads = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.beads
        ];
      };
    };
}
