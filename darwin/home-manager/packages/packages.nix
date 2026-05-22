{ pkgs }:
(with pkgs; [
  anki-bin
  arp-scan
  bat
  bottom
  bun
  curl
  delta
  direnv
  docker
  eza
  fastfetch
  fd
  fzf
  gat
  gh
  ghq
  git
  gitleaks
  gnugrep
  google-chrome
  grpcurl
  jpegoptim
  jq
  lazygit
  mecab
  mise
  mosh
  multitail
  # mpv  # Temporarily disabled due to Swift build failure in nixpkgs unstable
  nerd-fonts.hack
  obsidian
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
  tmux
  tree
  vscode
  xan
  xdg-ninja
  zoom-us
  zoxide
  zsh
]) ++ [
  (pkgs.callPackage ./gwq.nix {})
]
