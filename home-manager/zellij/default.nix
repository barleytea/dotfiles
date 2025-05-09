{ pkgs, ... }:
let
  readFile = builtins.readFile;
  configTemplate = builtins.readFile ./config.kdl;

  copyCommand = if pkgs.stdenv.isDarwin then
    "pbcopy"
  else if pkgs.stdenv.isLinux then
    "xsel --clipboard --input"
  else
    "pbcopy";

  # テンプレート内の copy_command を置換
  config = builtins.replaceStrings
    ["copy_command \"pbcopy\""]
    ["copy_command \"${copyCommand}\""]
    configTemplate;
in {
  programs.zellij = {
    enable = true;
  };

  home.file.".config/zellij/config.kdl".text = config;
}
