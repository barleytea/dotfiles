{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) readFile;
  pwd = (import ./pwd.nix { inherit config; }).pwd;
  configFile = file: {
    "nvim/${file}".source = pkgs.substituteAll (
      {
        src = ./. + "/${file}";
      }
    );
  };
  configFiles = files: builtins.foldl' (x: y: x // y) { } (map configFile files);
in {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    extraPackages = with pkgs; [
      lua-language-server
      nil
      stylua
      # TODO
    ];
    plugins = with pkgs.vimPlugins; [ lazy-nvim ];

    extraLuaConfig = 
      let
        plugins = with pkgs.vimPlugins; [
          # TODO  
        ];
        mkEntryFromDrv = drv:
          if lib.isDerivation drv then
            { name = "${lib.getName drv}"; path = drv; }
          else
            drv;
        lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
      in
      ''
        require("config.base")
        require("lazy").setup({
          debug = true,
          defaults = {
            lazy = true,
          },
          -- dev = {
          --   path = "${lazyPath}",
          --   patterns = { "." },
          --   fallback = true,
          -- },
          spec = {
            { "LazyVim/LazyVim", import = "lazyvim.plugins" },
            { "nvim-telescope/telescope-fzf-native.nvim", enabled = true },
            -- disable mason.nvim, use programs.neovim.extraPackages
            { "williamboman/mason-lspconfig.nvim", enabled = false },
            { "williamboman/mason.nvim", enabled = false },
            { import = "plugins" },
          },
        })
      '';
  };

  xdg.configFile."nvim/lua" = {
    source = config.lib.file.mkOutOfStoreSymlink "${pwd}/lua";
  };

  imports = [
    ./treesitter-parser.nix
  ];
}