{pkgs, ...}: {
  imports = [
    ./options.nix
    ./keymaps.nix
    ./colorschemes.nix
    ./plugins/lsp.nix
    ./plugins/completion.nix
    ./plugins/ui.nix
    ./plugins/editor.nix
    ./plugins/git.nix
  ];

  extraPackages = with pkgs; [
    go
    gopls
    lua-language-server
    stylua
    nil # unstable 前提なので常に含める
  ];
}
