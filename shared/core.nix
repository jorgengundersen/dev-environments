_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.core = pkgs.mkShell {
        packages = with pkgs; [
          less
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
