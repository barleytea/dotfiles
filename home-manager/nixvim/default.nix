{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./options.nix
    ./keymaps.nix
    ./colorschemes.nix
    ./plugins/lsp.nix
    ./plugins/completion.nix
    ./plugins/ui.nix
    ./plugins/editor.nix
    ./plugins/git.nix
    ./vscode.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    # Extra packages for language servers and formatters
    extraPackages = with pkgs; [
      # Language servers
      lua-language-server
      stylua
      # Add more packages as needed
    ];
  };
}
