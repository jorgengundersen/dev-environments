{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      devShells.opencode = inputs.nixpkgs.legacyPackages.${system}.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.opencode
        ];
      };
    };
}
