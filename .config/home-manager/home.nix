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
      git
      curl
    ];
  };

  programs.home-manager.enable = true;
}
