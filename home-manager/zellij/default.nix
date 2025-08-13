{ pkgs, ... }:
let
  readFile = builtins.readFile;
  configTemplate = builtins.readFile ./config.kdl;

  copyCommand = if pkgs.stdenv.isDarwin then
    "pbcopy"
  else if pkgs.stdenv.isLinux then
    # wl-copyが存在する場合は使用、なければxselにフォールバック
    "sh -c 'if command -v wl-copy >/dev/null 2>&1; then wl-copy; else xsel --clipboard --input; fi'"
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
