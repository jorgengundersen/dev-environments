_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.duckdb = pkgs.mkShell {
        packages = [ pkgs.duckdb ];
      };
    };
}
