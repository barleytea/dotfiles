# Homebrew 設定
{ pkgs, ... }: {
  imports = [ ../common.nix ];

  # Homebrew を通常ユーザー権限で実行するための設定
  users.users.miyoshi_s = {
    home = "/Users/miyoshi_s";
  };

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      #cleanup = "uninstall";
    };
    taps = [
      "sanemat/font"
      "aquaproj/aqua"
      "daipeihust/tap"
      "harelba/q"
      "koekeishiya/formulae"
    ];
    brews = [
      "aqua"
      "daipeihust/tap/im-select"
      "mas"
      "mise"
      "n"
      "uv"
      "harelba/q/q"
      "koekeishiya/formulae/skhd"
      "koekeishiya/formulae/yabai"
    ];
    casks = [
      "android-studio"
      "apparency"
      "appcleaner"
      "caffeine"
      "cursor"
      "devutils"
      "dbeaver-community"
      "fig"
      "finicky"
      "font-hack-nerd-font"
      "gfxcardstatus"
      "ghostty"
      "google-japanese-ime"
      "hammerspoon"
      "iterm2"
      "lm-studio"
      "miro"
      "nosql-workbench"
      "notion"
      "plain-clip"
      "raycast"
      "the-unarchiver"
      "xquartz"
    ];
    masApps = {
      # LINE = 539883307;
      # Xcode = 497799835;
    };
  };
}
