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
    ./skhd
    ./starship
    ./tmux
    ./wezterm
    ./yabai
    ./yazi
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
      bun
      cairo
      curl
      delta
      direnv
      docker
      eza
      fastfetch
      fd
      fftw
      fontforge
      fzf
      gat
      gh
      ghq
      git
      gitflow
      glib
      gnugrep
      golangci-lint
      google-chrome
      grpcurl
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
      protoc-gen-go
      protoc-gen-go-grpc
      ripgrep
      rustup
      sheldon
      slack
      socat
      stack
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
