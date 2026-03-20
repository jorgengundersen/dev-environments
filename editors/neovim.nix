_: {
  perSystem =
    { pkgs, ... }:
    {
      devShells.neovim = pkgs.mkShell {
        packages = with pkgs; [
          neovim
          tree-sitter
          nil
          gopls
          rust-analyzer
        ];
      };
    };

  flake.homeModules.neovim =
    { pkgs, ... }:
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        plugins = with pkgs.vimPlugins; [
          nvim-treesitter.withAllGrammars
          nvim-lspconfig
        ];
        extraLuaConfig = ''
          local lspconfig = require('lspconfig')
          lspconfig.nil_ls.setup{}
          lspconfig.gopls.setup{}
          lspconfig.rust_analyzer.setup{}
        '';
      };
    };
}
