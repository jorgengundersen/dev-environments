_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.core = pkgs.mkShell {
        packages = with pkgs; [
          bubblewrap
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
