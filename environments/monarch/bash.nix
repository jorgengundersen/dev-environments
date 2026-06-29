{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.sessionVariables = {
    LS_COLORS = "ow=01;33";
    MANWIDTH = "999";
    LESS = "-R -F -X";
  };

  home.sessionPath = [
    "$MONARCH_REALM_ROOT/.monarch/bin"
    "$HOME/.local/bin"
  ];

  home.activation.createMonarchStateDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p \
      "${config.xdg.configHome}" \
      "${config.xdg.dataHome}" \
      "${config.xdg.cacheHome}" \
      "${config.xdg.stateHome}" \
      "${config.xdg.stateHome}/pi/agent" \
      "${config.xdg.stateHome}/codex" \
      "${config.xdg.stateHome}/gh" \
      "${config.xdg.stateHome}/claude"
  '';

  programs.readline.extraConfig = ''
    set colored-stats on
    set colored-completion-prefix on
  '';

  programs.bash = {
    shellAliases = {
      python = "python3";
      c = "clear";
      t = "tmux";
      ta = "tmux attach";
      g = "git";
      gs = "git status";
      ga = "git add";
      gc = "git commit -m";
      grep = "grep --color=auto";
      ll = lib.mkForce "ls -alF";
      la = "ls -A";
      l = "ls -CF";
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

      config_root="''${MONARCH_CONFIG_ROOT:-''${XDG_CONFIG_HOME:-$HOME/.config}/monarch}"
      sources="''${MONARCH_BASH_SOURCES:-$config_root/session.local.sh:$config_root/session.secrets.sh}"

      IFS=':' read -r -a source_files <<< "$sources"
      for file in "''${source_files[@]}"; do
        if [[ -n "$file" && -f "$file" ]]; then
          . "$file"
        fi
      done
    '';
  };
}
