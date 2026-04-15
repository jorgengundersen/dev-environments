_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.bash = pkgs.mkShell {
        packages = [ pkgs.bash-completion ];
      };
    };

  flake.homeModules.bash = _: {
    programs.bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
        gs = "git status";
        gd = "git diff";
        gl = "git log --oneline --graph --decorate";
      };
    };
  };
}
