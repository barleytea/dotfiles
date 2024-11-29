{
  config,
  pkgs,
  ...
}: let
 
in {
  imports = [ 
    ./pkgs.nix
    ./config
    ../applications
    ../shell
  ];
}
