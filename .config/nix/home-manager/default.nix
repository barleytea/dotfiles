{
  config,
  pkgs,
  ...
}: let
  username = if builtins.getEnv "USER" == "runner" then builtins.getEnv "USER" else "miyoshi_s";
  home = if builtins.currentSystem == "x86_64-linux" then "/home/${username}" else "/Users/${username}";
in {

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = username;
    homeDirectory = home;
    stateVersion = "24.05";
    packages = with pkgs; [
      arp-scan
      asdf-vm
      curl
      gat
      bottom
      glib
      cairo
      docker
      eza
      fd
      fftw
      fish
      fontforge
      fzf
      gh
      ghq
      git
      gitflow
      go
      google-chrome
      gnugrep
      stack
      hub
      jpegoptim
      jq
      krb5
      kubectx
      maven
      mecab
      minikube
      neofetch
      peco
      postgresql
      postman
      protobuf
      pyenv
      rbenv
      ripgrep
      slack
      socat
      starship
      tmux
      tree
      vscode
      wezterm
      zoom-us
      zplug
      zsh
    ];
  };

  programs.home-manager.enable = true;
}
