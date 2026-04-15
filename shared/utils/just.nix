_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.just = pkgs.mkShell {
        packages = [ pkgs.just ];
      };
    };
}
