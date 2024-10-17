{
  config,
  pkgs,
  ...
}: let
  username = builtins.getEnv "DARWIN_USER";
  username = if username == "" then builtins.getEnv "USER" else username;
  username = if username == "" then "miyoshi_s" else username;
in {

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = username;
    homeDirectory = "/Users/${username}";
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
      neovim
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
