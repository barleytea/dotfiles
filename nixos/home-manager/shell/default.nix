{
  config,
  pkgs,
  ...
}: let

in {
  imports = [
    ./zsh
  ];
}
