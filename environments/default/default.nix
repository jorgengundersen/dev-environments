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
    "codex"
    "copilot"
    "pi"
    "dolt"
    "beads"
    "linters"
    "git"
    "glow"
    "typst"
    "mermaid"
    "afk"
    "opencode"
  ];
in
{
  perSystem =
    { self', pkgs, ... }:
    let
      missingShells = builtins.filter (name: !(builtins.hasAttr name self'.devShells)) defaultProfile;
    in
    {
      devShells.default =
        if missingShells == [ ] then
          pkgs.mkShell {
            inputsFrom = builtins.map (name: self'.devShells.${name}) defaultProfile;
          }
        else
          throw "defaultProfile references missing devShells: ${builtins.concatStringsSep ", " missingShells}";
    };
}
