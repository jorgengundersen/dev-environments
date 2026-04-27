_: {
  perSystem =
    { pkgs, pkgsUnstable, ... }:
    {
      devShells.neovim = pkgs.mkShell {
        packages = with pkgs; [
          pkgsUnstable.neovim
          tree-sitter
          nil
          gopls
          rust-analyzer
        ];
      };
    };

  flake.homeModules.neovim =
    {
      pkgs,
      pkgsUnstable ? pkgs,
      ...
    }:
    let
      nvimPkgs = pkgsUnstable;
    in
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        package = nvimPkgs.neovim;
        withRuby = true;
        withPython3 = true;
        plugins = with nvimPkgs.vimPlugins; [
          nvim-treesitter.withAllGrammars
          nvim-lspconfig
        ];
        initLua = ''
          local lspconfig = require('lspconfig')
          lspconfig.nil_ls.setup{}
          lspconfig.gopls.setup{}
          lspconfig.rust_analyzer.setup{}
        '';
      };
    };
}
