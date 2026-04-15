_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.dolt = pkgs.mkShell {
        packages = [ pkgs.dolt ];
      };
    };
}
