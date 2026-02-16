{ config, ... }:
let
  pwd = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles/darwin/home-manager";
in
{
  inherit pwd;
}
