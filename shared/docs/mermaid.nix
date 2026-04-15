_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.mermaid = pkgs.mkShell {
        packages = [ pkgs.mermaid-cli ];
      };
    };
}
