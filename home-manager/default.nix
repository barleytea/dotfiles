{
  config,
  pkgs,
  ...
}: let
  utils = import ./utils/utils.nix { inherit pkgs; };
in {

  # nixpkgsConfig is handled by useGlobalPkgs in NixOS configurations
  # For standalone home-manager, this is still needed:
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

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
    ./security/kali
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
      nerd-fonts.hack
      obsidian
      peco
      pnpm
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
      xan
      zoom-us
      zsh
    ] ++ (if pkgs.stdenv.isLinux then [
      # Linux (NixOS) specific packages
      lmstudio
      git-credential-manager
    ] else []);
  };

  # Enable security tools (Kali Linux) on Linux systems
  security.kali.enable = pkgs.stdenv.isLinux;
  security.kali.includeNetwork = true;
  security.kali.includeWeb = true;
  security.kali.includePassword = true;
  security.kali.includeExploitation = true;
  security.kali.includeReverse = true;
  security.kali.includeForensics = true;
  security.kali.includeWireless = true;
}
