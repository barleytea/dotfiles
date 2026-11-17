{ pkgs }:
# nixpkgs の更新を待たず、Slack 公式の macOS リリースを使う。
pkgs.slack.overrideAttrs (_: {
  version = "4.53.269";
  src = pkgs.fetchurl {
    url = "https://downloads.slack-edge.com/desktop-releases/mac/arm64/4.53.269/Slack-4.53.269-macOS.dmg";
    hash = "sha256-+U6MKxR7/Q04vqV0KsBai40kIB+TipaC9+3n7i7TZ68=";
  };
})
