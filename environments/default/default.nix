_:
let
  defaultProfile = [
    "core"
    "bash"
    "prompt"
    "fzf"
    "go"
    "rust"
    "node"
    "python"
    "bun"
    "neovim"
    "claude"
    "copilot"
    "dolt"
    "beads"
    "linters"
    "git"
    "glow"
    "afk"
    "opencode"
  ];
in
{
  perSystem =
    { self', pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        inputsFrom = builtins.map (name: self'.devShells.${name}) defaultProfile;
      };
    };
}
