_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.prompt = pkgs.mkShell {
        packages = [ pkgs.starship ];
      };
    };

  flake.homeModules.prompt = _: {
    programs.starship = {
      enable = true;
      enableBashIntegration = true;
    };
  };
}
