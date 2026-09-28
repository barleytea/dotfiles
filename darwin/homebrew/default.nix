# Homebrew 設定
{ pkgs, ... }:
let
  packages = import ./packages.nix;
in
{
  imports = [ ../common.nix ];

  # Homebrew を通常ユーザー権限で実行するための設定
  users.users.miyoshi_s = {
    home = "/Users/miyoshi_s";
  };

  # パッケージ一覧の正本は ./packages.nix。
  # nix-darwin は Brewfile に trusted: true を付与するため、
  # nix-darwin 経由の適用では信頼設定が自動で解決される。
  # 手動で brew を実行する場合の信頼設定は
  # darwin/home-manager/homebrew/default.nix が同じ正本から生成する。
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      #cleanup = "uninstall";
    };
    inherit (packages) taps brews casks;
    masApps = {
      # LINE = 539883307;
      # Xcode = 497799835;
    };
  };
}
