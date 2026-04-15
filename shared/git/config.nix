_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.git = pkgs.mkShell {
        packages = with pkgs; [
          git
          gh
          delta
        ];
      };
    };

  flake.homeModules.git = _: {
    programs.git = {
      enable = true;
      delta.enable = true;
      aliases = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
        lg = "log --oneline --graph --decorate";
      };
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };
}
