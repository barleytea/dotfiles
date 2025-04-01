{pkgs, ...}: {
  imports = [ ../common.nix ];
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      #cleanup = "uninstall";
    };
    taps = [
      "mscharley/homebrew"
      "sanemat/font"
      "koekeishiya/formulae"
      "aquaproj/aqua"
      "daipeihust/tap"
    ];
    brews = [
      "aqua"
      "daipeihust/tap/im-select"
      "mas"
      "mise"
      "n"
      "skhd"
      "yabai"
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
      "font-hack-nerd-font"
      "gfxcardstatus"
      "ghostty"
      "google-japanese-ime"
      "hammerspoon"
      "iterm2"
      "miro"
      "nosql-workbench"
      "notion"
      "plain-clip"
      "raycast"
      "rstudio"
      "scroll-reverser"
      "the-unarchiver"
      "xquartz"
    ];
    masApps = {
      # LINE = 539883307;
      # Xcode = 497799835;
    };
  };
}
