_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.tmux = pkgs.mkShell {
        packages = [ pkgs.tmux ];
      };
    };

  flake.homeModules.tmux = {
    programs.tmux = {
      enable = true;
      terminal = "screen-256color";
    };
  };
}
