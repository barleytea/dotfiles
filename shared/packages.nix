{ pkgs }:

# プラットフォーム共通のパッケージリスト
# home-manager/default.nix から抽出
with pkgs; [
  # Core utilities
  bat
  bottom
  curl
  delta
  direnv
  eza
  fastfetch
  fd
  fzf
  gh
  ghq
  git
  gitflow
  gitleaks
  jq
  lazygit
  neofetch
  peco
  ripgrep
  tree
  tmux
  zsh

  # Development tools
  bun
  maven
  mise
  neovim-remote
  pnpm
  pre-commit
  stack
  terraform

  # Python versions (複数バージョン管理)
  python312
  python313
  
  # Python tools
  python313Packages.pipx

  # Network tools
  arp-scan
  grpcurl
  hub
  socat

  # System tools
  docker
  krb5
  kubectx
  minikube
  postgresql
  xdg-ninja

  # Japanese support
  mecab

  # Fonts
  nerd-fonts.hack

  # Build tools and libraries
  cairo
  fftw
  fontforge
  glib
  gnugrep
  protobuf
  protoc-gen-go
  protoc-gen-go-grpc

  # Media tools
  jpegoptim

  # Development tools
  rustup
  sheldon

  # GUI applications (platform-specific handling in individual configs)
  anki-bin
  google-chrome
  obsidian
  postman
  slack
  vscode
  wezterm
  zoom-us
]
