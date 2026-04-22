_:
let
  defaultProfile = [
    "core"
    "bash"
    "tmux"
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
    "just"
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
            NIX_BUILD_CORES = "4";
            CARGO_BUILD_JOBS = "4";
            NIX_CONFIG = ''
              cores = 4
              max-jobs = 1
            '';
          }
        else
          throw "defaultProfile references missing devShells: ${builtins.concatStringsSep ", " missingShells}";
    };
}
