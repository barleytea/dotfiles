{ config, pkgs, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles";
  claudeConfigPath = "${dotfilesPath}/modules/home/claude/config";
  geminiConfigPath = "${dotfilesPath}/modules/home/gemini/config";

  # AGENTS.md の OS 別レンダリングは Claude / Gemini / Codex / Copilot で共有する。
  # （以前は未レンダリングの生 AGENTS.md を直接リンクしており、Linux でも
  #   Darwin 向け gh 認証手順が表示されるバグがあった）
  renderedAgents = import "${claudeConfigPath}/render-agents.nix" {inherit pkgs;};
in
{
  home.activation.creategeminiSymlinks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.gemini"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${renderedAgents}" "${config.home.homeDirectory}/.gemini/GEMINI.md"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${geminiConfigPath}/settings.json" "${config.home.homeDirectory}/.gemini/settings.json"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${geminiConfigPath}/commands" "${config.home.homeDirectory}/.gemini/commands"
  '';
}
