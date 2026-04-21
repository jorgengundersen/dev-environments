{ lib, pkgs, ... }:
{
  home.sessionVariables = {
    LS_COLORS = "ow=01;33";
    MANWIDTH = "999";
    TERMINAL = "wezterm";
  };

  programs.readline.extraConfig = ''
    set colored-stats on
    set colored-completion-prefix on
  '';

  programs.bash = {
    shellAliases = {
      python = "python3";
      c = "clear";
      n = "nvim";
      t = "tmux";
      ta = "tmux attach";
      ts = "tmux-sessionizer";
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
      lg = "lazygit";
      tree = "tree --dirsfirst -F";
      mkdir = "mkdir -p -v";
      ll = "ls -latr";
      cp = "cp -iv";
      mv = "mv -iv";
      rm = "rm -iv";
      grep = "grep --color=auto";
      df = "df -h";
      free = "free -m";
      ".." = "cd ..;pwd";
      "..." = "cd ../..;pwd";
      "...." = "cd ../../..;pwd";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      ls = "ls --color=auto";
    };

    initExtra = ''
      set -o vi

      shopt -s autocd
      shopt -s cdspell
      shopt -s cmdhist
      shopt -s direxpand
      shopt -s dirspell
      shopt -s hostcomplete

      HISTTIMEFORMAT="%F %T "

      if [[ -f "$HOME/currently" ]]; then
        alias distracted="cat $HOME/currently"
        alias focus="nvim $HOME/currently"
      fi

      config_root="''${DEVENV_CONFIG_ROOT:-''${XDG_CONFIG_HOME:-$HOME/.config}/dev-environments}"
      sources="''${DEVENV_BASH_SOURCES:-$config_root/default.local.sh:$config_root/default.secrets.sh}"

      IFS=':' read -r -a source_files <<< "$sources"
      for file in "''${source_files[@]}"; do
        if [[ -n "$file" && -f "$file" ]]; then
          . "$file"
        fi
      done
    '';
  };
}
