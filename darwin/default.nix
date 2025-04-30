{pkgs, ...}: {
  imports = [
    ./common.nix
    ./homebrew
    ./system
  ];
}
