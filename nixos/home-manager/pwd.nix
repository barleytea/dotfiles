{ config, ... }:
let
  pwd = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles/nixos/home-manager";
in
{
  inherit pwd;
}
