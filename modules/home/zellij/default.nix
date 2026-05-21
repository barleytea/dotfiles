{ pkgs, ... }:
let
  readFile = builtins.readFile;
  configTemplate = builtins.readFile ./config.kdl;

  copyCommand = if pkgs.stdenv.isDarwin then
    "pbcopy"
  else if pkgs.stdenv.isLinux then
    # Wayland環境でより確実なクリップボードアクセス
    # KDL raw stringを使用してエスケープの問題を回避
    ''wl-copy''
  else
    "pbcopy";

  # mouse_mode は Darwin のみ true（旧 nixos 側は false）
  mouseMode = if pkgs.stdenv.isDarwin then "true" else "false";

  config = builtins.replaceStrings
    [ "copy_command \"pbcopy\""
      "mouse_mode true"
    ]
    [ "copy_command \"${copyCommand}\""
      "mouse_mode ${mouseMode}"
    ]
    configTemplate;
in {
  programs.zellij = {
    enable = true;
  };

  home.file.".config/zellij/config.kdl".text = config;
  home.file.".config/zellij/layouts/webdev.kdl".source = ./layouts/webdev.kdl;
  home.file.".config/zellij/layouts/investigate.kdl".source = ./layouts/investigate.kdl;
}
