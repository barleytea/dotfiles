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
        CopilotChat-nvim
        cmp-buffer
        cmp-nvim-lsp
        cmp-path
        cmp-vsnip
        copilot-lua
        copilot-vim
        dracula-nvim
        fidget-nvim
        fzf-lsp-nvim
        fzf-vim
        lspkind-nvim
        lspsaga-nvim
        nvim-cmp
        nvim-lspconfig
        nvim-treesitter
        rust-vim
        vim-airline
        vim-airline-themes
        vim-vsnip
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