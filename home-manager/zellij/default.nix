let
  readFile = builtins.readFile;
in {
  programs.zellij = {
    enable = true;
  };

  home.file.".config/zellij/config.kdl".text = readFile ./config.kdl;
}
