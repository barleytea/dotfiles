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
      "chromium"
      "docker"
      "firefox"
      "font-hack-nerd-font"
      "gfxcardstatus"
      "google-chrome"
      "google-japanese-ime"
      "google-japanese-ime-dev"
      "iterm2"
      "kindle"
      "notion"
      "plain-clip"
      "postman"
      "raycast"
      "robo-3t"
      "rstudio"
      "scroll-reverser"
      "skype"
      "slack"
      "the-unarchiver"
      "visual-studio-code"
      "wezterm"
      "xquartz"
      "zoom"
    ];
    masApps = {
      LINE = 539883307;
      Xcode = 497799835;
    };
  };
}