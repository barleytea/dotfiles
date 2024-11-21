{
  config,
  pkgs,
  ...
}: let
  inherit (builtins) readFile;
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
    coc.enable = true;
    extraPackages = with pkgs; [
      lua-language-server
      nodePackages.typescript-language-server
      bash-language-server
      vim-language-server
      emmet-language-server
      gopls
      nil
      pyright
      stylua
      nixfmt-rfc-style
      skkDictionaries.l
    ];
    plugins = with pkgs.vimPlugins; [ lazy-nvim ];
  };

  xdg.configFile = configFiles [
    "./lua/base.lua"
  ];

  imports = [
    ./plugins.nix
    ./treesitter-parser.nix
  ];
}