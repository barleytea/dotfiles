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
      "aquaproj/aqua"
      "daipeihust/tap"
      "koekeishiya/formulae"
    ];
    brews = [
      "aqua"
      "daipeihust/tap/im-select"
      "mas"
      "mise"
      "n"
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
