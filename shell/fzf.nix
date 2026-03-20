_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.fzf = pkgs.mkShell {
        packages = [ pkgs.fzf ];
      };
    };

  flake.homeModules.fzf = _: {
    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
    };
  };
}
