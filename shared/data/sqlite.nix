_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.sqlite = pkgs.mkShell {
        packages = [ pkgs.sqlite ];
      };
    };
}
