{ pkgs }:
# nixpkgs の更新を待たず、Slack 公式の Linux リリースを使う。
pkgs.slack.overrideAttrs (_: {
  version = "4.52.182";
  src = pkgs.fetchurl {
    url = "https://downloads.slack-edge.com/desktop-releases/linux/x64/4.52.182/slack-desktop-4.52.182-amd64.deb";
    hash = "sha256-Vo+edqFDperWlkUZLjgTGJf4WvdkXX2BiX82/arI9wA=";
  };
})
