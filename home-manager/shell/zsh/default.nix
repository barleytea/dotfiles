{
  config,
  lib,
  pkgs,
  ...
}: {
  home.file.".zshenv".source = ./.zshenv;

  xdg = {
    enable = true;
    configFile = {
      # 1. Load basic settings first
      "zsh/config/000-env.zsh".source = ./config/env.zsh;
      "zsh/config/001-path.zsh".source = ./config/path.zsh;
      "zsh/config/002-options.zsh".source = ./config/options.zsh;

      # 2. Function settings
      "zsh/config/100-completion.zsh".source = ./config/completion.zsh;
      "zsh/config/101-functions.zsh".source = ./config/functions.zsh;
      "zsh/config/102-keybinds.zsh".source = ./config/keybinds.zsh;

      # 3. Tool settings
      "zsh/config/tools/200-starship.zsh".source = ./config/starship.zsh;
      "zsh/config/tools/201-sheldon.zsh".source = ./config/sheldon.zsh;
      "zsh/config/tools/202-atuin.zsh".source = ./config/atuin.zsh;
      "zsh/config/tools/203-asdf.zsh".source = ./config/asdf.zsh;
      "zsh/config/tools/204-fastfetch.zsh".source = ./config/fastfetch.zsh;
      "zsh/config/tools/205-direnv.zsh".source = ./config/direnv.zsh;

      # 4. Alias settings
      "zsh/config/900-aliases.zsh".source = ./config/aliases.zsh;

      # 5. Main .zshrc
      "zsh/.zshrc".source = ./.zshrc;
    };
  };
}
