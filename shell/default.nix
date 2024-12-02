{
  config,
  pkgs,
  ...
}: let

in {
  imports = [
    ./zsh
    ./fish
  ];
}
