_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.git = pkgs.mkShell {
        packages = with pkgs; [
          git
          delta
        ];
      };
    };

  flake.homeModules.git = _: {
    programs.git = {
      enable = true;
      settings = {
        alias = {
          co = "checkout";
          br = "branch";
          ci = "commit";
          st = "status";
          lg = "log --oneline --graph --decorate";
        };
        init.defaultBranch = "main";
      };
      signing.format = "openpgp";
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
  };
}
