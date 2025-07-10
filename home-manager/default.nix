{
  config,
  pkgs,
  ...
}: let
  utils = import ./utils/utils.nix { inherit pkgs; };
  # golangci-lintの特定バージョンを取得するための関数
  getGolangciLint = pkgs: let
    version = "1.64.5";
    platform = if pkgs.stdenv.hostPlatform.isDarwin then
      if pkgs.stdenv.hostPlatform.isAarch64 then "darwin-arm64"
      else "darwin-amd64"
    else pkgs.stdenv.hostPlatform.system;
  in pkgs.stdenv.mkDerivation {
    name = "golangci-lint-${version}";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/golangci/golangci-lint/releases/download/v${version}/golangci-lint-${version}-${platform}.tar.gz";
      sha256 = if pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64 then
        "sha256-jE8R7zoi1hDdWDagnJjpRLQFYk+TLyDH5yrnirxVIxE=" # darwin-arm64用ハッシュ
      else
        "sha256-doHD6RlJEDBVjvObbMr0m+Gz0Z3mEdMMAq7IKNrYIsE="; # それ以外のハッシュ
    };

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/bin
      cp -r golangci-lint-${version}-${platform}/golangci-lint $out/bin/
      chmod +x $out/bin/golangci-lint
    '';
  };
in {

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
    ./git
    ./k9s
    ./mise
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
      (getGolangciLint pkgs)  # 自前でバージョン固定したパッケージを使う
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
      neofetch
      neovim-remote
      nerd-fonts.hack
      obsidian
      peco
      pnpm
      postgresql
      postman
      pre-commit
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
