_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.glow = pkgs.mkShell {
        packages = [ pkgs.glow ];
      };
    };
}
