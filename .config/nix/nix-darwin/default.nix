{pkgs, ...}: {

  nix = {
    optimise.automatic = true;
    settings = {
      experimental-features = "nix-command flakes";
      max-jobs = 8;
    };
  };
  services.nix-daemon.enable = true;

  system = {
    stateVersion = 5;
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "left";
      };
    };
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      #cleanup = "uninstall";
    };
    taps = [
      "homebrew/bundle"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "mscharley/homebrew"
      "sanemat/font"
    ];
    brews = [
      "mise"
      "node"
      "nvm"
      "sanemat/font/ricty"
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
      "google-japanese-ime-dev"
      "iterm2"
      "notion"
      "plain-clip"
      "raycast"
      "robo3t"
      "rstudio"
      "scroll-reverser"
      "the-unarchiver"
      "xquartz"
    ];
    masApps = {
      LINE = 539883307;
      Xcode = 497799835;
    };
  };
}