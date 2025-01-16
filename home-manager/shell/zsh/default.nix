{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    initExtra = builtins.readFile ./.zshrc;
    envExtra = builtins.readFile ./.zshenv;
  };

  xdg = {
    enable = true;
    configFile = {
      "zsh/config/env.zsh".source = ./config/env.zsh;
      "zsh/config/aliases.zsh".source = ./config/aliases.zsh;
      "zsh/config/completion.zsh".source = ./config/completion.zsh;
      "zsh/config/functions.zsh".source = ./config/functions.zsh;
      "zsh/config/keybinds.zsh".source = ./config/keybinds.zsh;
      "zsh/config/options.zsh".source = ./config/options.zsh;
      "zsh/config/path.zsh".source = ./config/path.zsh;
      "zsh/config/tools/starship.zsh".source = ./config/tools/starship.zsh;
      "zsh/config/tools/sheldon.zsh".source = ./config/tools/sheldon.zsh;
      "zsh/config/tools/atuin.zsh".source = ./config/tools/atuin.zsh;
    };
  };
}
