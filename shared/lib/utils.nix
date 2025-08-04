{ lib, pkgs }:

rec {
  # プラットフォーム検出
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
  isNixOS = isLinux; # NixOS前提でLinuxを扱う

  # システム情報取得
  username = if builtins.getEnv "USER" == "" then "miyoshi_s" else builtins.getEnv "USER";
  home = if isDarwin then "/Users/${username}" else "/home/${username}";

  # GUI アプリケーションのプラットフォーム固有リスト
  guiPackages = with pkgs;
    lib.optionals isDarwin [
      # macOS specific GUI apps
      anki-bin
      google-chrome
      obsidian
      postman
      slack
      vscode
      wezterm
      zoom-us
    ] ++ lib.optionals isLinux [
      # Linux specific GUI apps
      firefox
      code-cursor
    ];

  # プラットフォーム固有の設定を条件付きで含める
  conditionalImports = darwinModules: linuxModules:
    (lib.optionals isDarwin darwinModules) ++
    (lib.optionals isLinux linuxModules);
}
