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
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/cask-versions"
      "homebrew/core"
      "mscharley/homebrew"
      "rcmdnk/file"
      "sanemat/font"
    ];
    brews = [ 
      "arp-scan"
      "asdf"
      "gat"
      "bottom"
      "glib"
      "cairo"
      "eza"
      "fd"
      "fftw"
      "fish"
      "fontforge"
      "fzf"
      "gh"
      "ghq"
      "git"
      "git-flow"
      "go"
      "grep"
      "haskell-stack"
      "hub"
      "jenv"
      "jpegoptim"
      "jq"
      "krb5"
      "kubectx"
      "mas"
      "openjdk"
      "maven"
      "mecab"
      "mecab-ipadic"
      "mise"
      "minikube"
      "neofetch"
      "node"
      "nvm"
      "peco"
      "postgresql"
      "protobuf"
      "pyenv"
      "rbenv"
      "ripgrep"
      "socat"
      "starship"
      "tmux"
      "tree"
      "zplug"
      "zsh"
      "rcmdnk/file/brew-file"
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