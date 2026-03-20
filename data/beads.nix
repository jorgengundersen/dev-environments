{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      devShells.beads = inputs.nixpkgs.legacyPackages.${system}.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.beads
        ];
      };
    };
}
