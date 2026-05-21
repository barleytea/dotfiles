{
  config,
  lib,
  pkgs,
  ...
}: let
  zshrcBase = pkgs.writeText "zshrc" (builtins.readFile ./.zshrc);
in {
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
      "zsh/config/tools/204-fastfetch.zsh".source = ./config/fastfetch.zsh;
      "zsh/config/tools/205-direnv.zsh".source = ./config/direnv.zsh;
      "zsh/config/tools/206-zoxide.zsh".source = ./config/zoxide.zsh;
      "zsh/config/tools/207-zellij.zsh".source = ./config/zellij.zsh;

      # 4. Alias settings
      "zsh/config/900-aliases.zsh".source = ./config/aliases.zsh;

      # 5. .zshrc は activation script で書き込み可能なファイルとして配置
      #    (safe-chain setup が書き込めるよう symlink ではなく実ファイルにする)
    };
  };

  # .zshrc を Nix store からコピーして書き込み可能な実ファイルとして配置
  home.activation.writeZshrc = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD rm -f '${config.xdg.configHome}/zsh/.zshrc'
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -D -m 644 \
      '${zshrcBase}' '${config.xdg.configHome}/zsh/.zshrc'
  '';
}
