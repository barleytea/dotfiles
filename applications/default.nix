{
  config,
  pkgs,
  ...
}: let

in {
  imports = [
    ./neovim
    ./starship
  ];
}
