_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.typst = pkgs.mkShell {
        packages = [ pkgs.typst ];
      };
    };
}
