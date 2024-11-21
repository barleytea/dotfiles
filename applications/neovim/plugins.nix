{
  pkgs,
  lib,
  config,
  sources,
  ...
}:
let
  substituteStrings = import ../../lib/substituteStrings.nix;
  pwd = (import ./pwd.nix { inherit config; }).pwd;

  vimdoc-ja = pkgs.vimUtils.buildVimPlugin {
    inherit (sources.vimdoc-ja) pname version src;
  };
in
{
  programs.neovim.extraLuaConfig = 

    let
      plugins = with pkgs.vimPlugins; [
        copilot-cmp
        copilot-lua
        copilot-vim
        CopilotChat-nvim
        nvim-lspconfig
        mason-nvim
        mason-lspconfig-nvim
        nvim-cmp
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        vim-vsnip
        cmp-vsnip
        lspkind-nvim
        lspsaga-nvim
        fidget-nvim
        nvim-treesitter
        fzf-vim
        fzf-lsp-nvim
        vim-airline
        vim-airline-themes
        dracula-nvim
        rust-vim
      ];
      mkEntryFromDrv =
        drv:
        if lib.isDerivation drv then
          {
            name = "${lib.getName drv}";
            path = drv;
          }
        else
          drv;
      lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
      lazyConfig = substituteStrings {
        file = ./init.lua;
        replacements = [
          {
            old = "@lazyPath@";
            new = "${lazyPath}";
          }
        ];
      };
    in
    ''
      ${lazyConfig}
    '';

  xdg.configFile."nvim/lua/plugins/" = {
    source = config.lib.file.mkOutOfStoreSymlink "${pwd}/lua/plugins";
  };
}