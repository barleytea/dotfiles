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
      "homebrew/bundle"
      "mscharley/homebrew"
      "sanemat/font"
    ];
    brews = [
      "mas"
      "mise"
      "n"
    ];
    casks = [
      "devutils"
      "android-studio"
      "apparency"
      "appcleaner"
      "authy"
      "caffeine"
      "font-hack-nerd-font"
      "gfxcardstatus"
      "google-japanese-ime"
      "iterm2"
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