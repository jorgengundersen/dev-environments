_:
let
  neovimPlugins =
    vimPlugins: with vimPlugins; [
      nvim-treesitter.withAllGrammars
      nvim-lspconfig
    ];

  neovimLspConfig = ''
    vim.lsp.enable({
      'nil_ls',
      'gopls',
      'rust_analyzer',
    })
  '';
in
{
  perSystem =
    { pkgs, pkgsUnstable, ... }:
    let
      neovimRuntime = pkgsUnstable.wrapNeovimUnstable pkgsUnstable.neovim-unwrapped {
        extraName = "-dev-env";
        plugins = neovimPlugins pkgsUnstable.vimPlugins;
        withRuby = true;
        withPython3 = true;

        # The default shell puts this Neovim before Home Manager's profile
        # wrapper in PATH, but it still reads the Home Manager init.lua.
        # Keep the plugin runtime available without replacing user config.
        wrapRc = false;
      };
    in
    {
      devShells.neovim = pkgs.mkShell {
        packages = [
          neovimRuntime
          pkgs.tree-sitter
          pkgs.nil
          pkgs.gopls
          pkgs.rust-analyzer
        ];
      };
    };

  flake.homeModules.neovim =
    {
      pkgs,
      ...
    }:
    {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        withRuby = true;
        withPython3 = true;
        plugins = neovimPlugins pkgs.vimPlugins;
        extraLuaConfig = neovimLspConfig;
      };
    };
}
