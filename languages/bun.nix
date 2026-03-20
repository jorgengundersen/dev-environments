_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.bun = pkgs.mkShell {
        packages = [ pkgs.bun ];
      };
    };
}
