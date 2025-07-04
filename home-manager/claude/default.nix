{ config, pkgs, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles";
  claudeConfigPath = "${dotfilesPath}/home-manager/claude/config";
in
{
  home.activation.createClaudeSymlinks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.config/claude"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${claudeConfigPath}/CLAUDE.md" "${config.home.homeDirectory}/.claude/CLAUDE.md"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${claudeConfigPath}/settings.json" "${config.home.homeDirectory}/.claude/settings.json"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${claudeConfigPath}/commands" "${config.home.homeDirectory}/.claude/commands"
  '';
}