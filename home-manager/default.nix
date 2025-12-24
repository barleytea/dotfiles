{
  config,
  pkgs,
  ...
}: let
  utils = import ./utils/utils.nix { inherit pkgs; };
in {

  # nixpkgs config is supplied by the caller (NixOS flake sets allowUnfree)

  imports = [
    ./alacritty
    ./atuin
    ./claude
    ./cz-git
    ./editorconfig
    ./gemini
    ./fcitx5
    ./git
    ./k9s
    ./lazygit
    ./mise
    ./nixvim
    ./hyprland
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
      anki-bin
      arp-scan
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
      gitleaks
      glib
      gnugrep
      google-chrome
      grpcurl
      hub
      jpegoptim
      jq
      krb5
      kubectx
      lazygit
      maven
      mecab
      minikube
      mise
      mpv
      neofetch
      neovim-remote
      obsidian
      peco
      pnpm
      pre-commit
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
      zoxide
      zsh
    ] ++ (if pkgs.stdenv.isLinux then [
      # Linux (NixOS) specific packages
      lmstudio
      git-credential-manager
    ] else []);
  };

  # Enable security tools (Kali Linux) on Linux systems
}
