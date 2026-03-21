{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.afk = pkgs.mkShell {
        packages = [
          inputs.afk.packages.${system}.default
        ];
      };
    };
}
