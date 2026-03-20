_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.node = pkgs.mkShell {
        packages = [ pkgs.nodejs ];
      };
    };
}
