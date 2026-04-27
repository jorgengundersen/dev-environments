{ inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.codex = pkgs.mkShell {
        packages = [
          inputs.llm-agents.packages.${system}.codex
        ];
        shellHook = ''
          if [ -n "''${HOME:-}" ]; then
            : "''${XDG_STATE_HOME:=$HOME/.local/state}"
          fi

          : "''${CODEX_HOME:=$XDG_STATE_HOME/codex}"

          export XDG_STATE_HOME
          export CODEX_HOME

          if [ -n "$CODEX_HOME" ] && [ ! -d "$CODEX_HOME" ]; then
            mkdir -p "$CODEX_HOME" >/dev/null 2>&1 || true
          fi
        '';
      };
    };

  flake.homeModules.codex = _: {
    home.sessionVariables = {
      CODEX_HOME = "$XDG_STATE_HOME/codex";
    };
  };
}
