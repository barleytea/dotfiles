{
  config,
  pkgs,
  inputs,
  ...
}: let
  utils = import ./utils/utils.nix { inherit pkgs; };
in {

  # nixpkgs config is supplied by the caller (NixOS flake sets allowUnfree)

  imports = [
    inputs.nixvim-config.homeManagerModules.default
    ./alacritty
    ./atuin
    ./claude
    ./cz-git
    ./editorconfig
    ./gemini
    ./fcitx5
    ./git
    ./ghostty
    ./k9s
    ./lazygit
    ./helix
    ./mise
    ./hyprland
    ./shell
    ./sheldon
    ./starship
    ./tmux
    ./wezterm
    ./yazi
    ./zellij
  ];

  home = {
    username = utils.username;
    homeDirectory = utils.home;
    stateVersion = "24.05";

    packages = (with pkgs; [
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
      # mpv  # Temporarily disabled due to Swift build failure in nixpkgs unstable
      nerd-fonts.hack
      neofetch
      neovim-remote
      obsidian
      peco
      pipx
      pnpm
      # pre-commit  # Temporarily disabled due to Swift build failure in nixpkgs unstable
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
      tmux
      tree
      vscode
      wezterm
      xan
      xdg-ninja
      zoom-us
      zoxide
      zsh
      # NixOS 専用パッケージ
      lmstudio
      git-credential-manager
    ]) ++ [
      (pkgs.callPackage ./packages/gwq.nix {})
    ];

    file.".local/bin/zellij-worktree-switcher" = {
      text = builtins.readFile ./scripts/zellij-worktree-switcher.sh;
      executable = true;
    };

    file.".local/bin/zellij-worktree-remove" = {
      text = builtins.readFile ./scripts/zellij-worktree-remove.sh;
      executable = true;
    };

    file.".local/bin/zellij-session-switcher" = {
      text = builtins.readFile ./scripts/zellij-session-switcher.sh;
      executable = true;
    };
  };

  # Enable security tools (Kali Linux) on Linux systems
}
