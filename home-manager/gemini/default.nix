{ config, pkgs, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles";
  geminiConfigPath = "${dotfilesPath}/home-manager/gemini/config";
in
{
  home.activation.creategeminiSymlinks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.gemini"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${geminiConfigPath}/GEMINI.md" "${config.home.homeDirectory}/.gemini/GEMINI.md"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${geminiConfigPath}/settings.json" "${config.home.homeDirectory}/.gemini/settings.json"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${geminiConfigPath}/commands" "${config.home.homeDirectory}/.gemini/commands"
  '';
}