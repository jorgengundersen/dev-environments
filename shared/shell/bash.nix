_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.bash = pkgs.mkShell {
        packages = [ pkgs.bash-completion ];
      };
    };

  flake.homeModules.bash = {
    home.sessionVariables = {
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_CACHE_HOME = "$HOME/.cache";
      XDG_DATA_HOME = "$HOME/.local/share";
      XDG_STATE_HOME = "$HOME/.local/state";
      EDITOR = "nvim";
      VISUAL = "nvim";
      LESS = "-R -F -X";
    };

    programs.readline = {
      enable = true;
      extraConfig = ''
        set show-all-if-ambiguous on
        set completion-ignore-case on
      '';
    };

    programs.bash = {
      enable = true;
      enableCompletion = true;
      historyControl = [
        "ignoredups"
        "erasedups"
      ];
      historyFileSize = 2000;
      historyIgnore = [
        "ls"
        "ll"
        "cd"
        "pwd"
        "exit"
        "clear"
        "history"
      ];
      historySize = 2000;
      shellAliases = {
        ll = "ls -alF";
        la = "ls -A";
        l = "ls -CF";
      };

      initExtra = ''
        shopt -s histappend
      '';
    };
  };
}
