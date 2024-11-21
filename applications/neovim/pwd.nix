{ config, ... }:
let
  pwd = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles/applications/neovim";
in
{
  inherit pwd;
}