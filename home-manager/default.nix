{
  config,
  pkgs,
  ...
}: let
  utils = import ./utils/utils.nix { inherit pkgs; };
in {

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./alacritty
    ./asdf
    ./atuin
    ./cz-git
    ./editorconfig
    ./git
    ./just
    ./k9s
    ./neovim
    ./shell
    ./sheldon
    ./starship
    ./tmux
    ./wezterm
    ./zellij
  ];

  home = {
    username = utils.username;
    homeDirectory = utils.home;
    stateVersion = "24.05";
    packages = with pkgs; [
      arp-scan
      asdf-vm
      bat
      bottom
      cairo
      curl
      delta
      docker
      eza
      fd
      fftw
      fish
      fontforge
      fzf
      gat
      gh
      ghq
      git
      gitflow
      glib
      gnugrep
      google-chrome
      hub
      jpegoptim
      jq
      just
      krb5
      kubectx
      lazygit
      maven
      mecab
      minikube
      neofetch
      neovim-remote
      nerd-fonts.hack
      peco
      postgresql
      postman
      protobuf
      ripgrep
      sheldon
      slack
      socat
      stack
      starship
      terraform
      tmux
      tree
      vscode
      wezterm
      xdg-ninja
      zoom-us
      zsh
    ];
  };
}
