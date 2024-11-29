{
  config,
  pkgs,
  ...
}: let
 
in {
  imports = [ 
    ./pkgs.nix
    ../applications
    ../shell
  ];
}
