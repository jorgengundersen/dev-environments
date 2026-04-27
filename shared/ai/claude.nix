{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.claude = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.claude-code
        ];
        shellHook = ''
          if [ -n "''${HOME:-}" ]; then
            : "''${XDG_STATE_HOME:=$HOME/.local/state}"
          fi

          : "''${CLAUDE_CONFIG_DIR:=$XDG_STATE_HOME/claude}"

          export XDG_STATE_HOME
          export CLAUDE_CONFIG_DIR

          if [ -n "$CLAUDE_CONFIG_DIR" ] && [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
            mkdir -p "$CLAUDE_CONFIG_DIR" >/dev/null 2>&1 || true
          fi
        '';
      };
    };

  flake.homeModules.claude = _: {
    home.sessionVariables = {
      CLAUDE_CONFIG_DIR = "$XDG_STATE_HOME/claude";
    };
  };
}
