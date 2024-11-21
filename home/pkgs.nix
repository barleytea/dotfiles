{
  config,
  pkgs,
  ...
}: let
  utils = import ./utils.nix { inherit pkgs; };
in {

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = utils.username;
    homeDirectory = utils.home;
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
      neovim-remote
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
}
