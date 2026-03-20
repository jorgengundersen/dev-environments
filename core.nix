_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.core = pkgs.mkShell {
        packages = with pkgs; [
          git
          gh
          jq
          yq
          ripgrep
          gnumake
          curl
          wget
          tree
          unzip
        ];
      };
    };
}
