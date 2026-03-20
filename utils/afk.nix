{ inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      devShells.afk = inputs.nixpkgs.legacyPackages.${system}.mkShell {
        packages = [
          inputs.afk.packages.${system}.default
        ];
      };
    };
}
