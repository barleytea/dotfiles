{
  config,
  pkgs,
  ...
}: let
  username = "miyoshi_s";
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
      asdf
      curl
      gat
      bottom
      glib
      cairo
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
      gnugrep
      stack
      hub
      jpegoptim
      jq
      krb5
      kubectx
      mas
      maven
      mecab
      minikube
      neofetch
      peco
      postgresql
      protobuf
      pyenv
      rbenv
      ripgrep
      socat
      starship
      tmux
      tree
      zplug
      zsh
    ];
  };

  programs.home-manager.enable = true;
}
