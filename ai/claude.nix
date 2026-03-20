{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      devShells.claude = inputs.nixpkgs.legacyPackages.${system}.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.claude-code
        ];
      };
    };
}
