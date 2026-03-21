_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.core = pkgs.mkShell {
        packages = with pkgs; [
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
