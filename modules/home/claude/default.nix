{ config, pkgs, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles";
  claudeConfigPath = "${dotfilesPath}/modules/home/claude/config";
  ghConfigBase = pkgs.writeText "gh-config" ''
    version: 1
    git_protocol: https
  '';

  # AGENTS.md の OS 別レンダリングは Claude / Gemini / Codex / Copilot で共有する。
  renderedAgents = import ./config/render-agents.nix {inherit pkgs;};
in
{
  home.activation.setupGhConfigDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p \
      "${config.home.homeDirectory}/.config/github-cli"
    if [ ! -f "${config.home.homeDirectory}/.config/github-cli/config.yml" ]; then
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -m 644 \
        '${ghConfigBase}' "${config.home.homeDirectory}/.config/github-cli/config.yml"
    fi
  '';

  home.activation.createClaudeSymlinks = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.config/claude"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.claude/commands"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.claude/skills"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${renderedAgents}" "${config.home.homeDirectory}/.claude/CLAUDE.md"
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sf "${claudeConfigPath}/statusline.sh" "${config.home.homeDirectory}/.claude/statusline.sh"

    # settings.json は base をマージスクリプトで生成した実ファイルにする（symlink ではない）。
    # dry-run 時は何も書き込まない（$DRY_RUN_CMD でパイプライン全体を bash -c にまとめてスキップ対象にする）。
    $DRY_RUN_CMD ${pkgs.bash}/bin/bash -c '
      PATH="${pkgs.jq}/bin:$PATH" ${pkgs.bash}/bin/bash "${claudeConfigPath}/merge-settings.sh" \
        "${claudeConfigPath}/settings.json" \
        > "${config.home.homeDirectory}/.claude/settings.json.tmp" \
        && ${pkgs.jq}/bin/jq empty "${config.home.homeDirectory}/.claude/settings.json.tmp" \
        && ${pkgs.coreutils}/bin/mv "${config.home.homeDirectory}/.claude/settings.json.tmp" "${config.home.homeDirectory}/.claude/settings.json"
    '

    # Link individual files from commands directory
    if [ -d "${claudeConfigPath}/commands" ]; then
      for file in "${claudeConfigPath}/commands"/*; do
        if [ -f "$file" ]; then
          filename=$(${pkgs.coreutils}/bin/basename "$file")
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$file" "${config.home.homeDirectory}/.claude/commands/$filename"
        fi
      done
    fi

    # Link skill directories from skills directory
    if [ -d "${claudeConfigPath}/skills" ]; then
      for skillDir in "${claudeConfigPath}/skills"/*; do
        if [ -d "$skillDir" ]; then
          skillName=$(${pkgs.coreutils}/bin/basename "$skillDir")
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$skillDir" "${config.home.homeDirectory}/.claude/skills/$skillName"
        fi
      done
    fi

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.claude/hooks"

    # Link hook scripts from hooks directory
    if [ -d "${claudeConfigPath}/hooks" ]; then
      for file in "${claudeConfigPath}/hooks"/*; do
        if [ -f "$file" ]; then
          filename=$(${pkgs.coreutils}/bin/basename "$file")
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$file" "${config.home.homeDirectory}/.claude/hooks/$filename"
        fi
      done
    fi

    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/.claude/agents"

    # Link agent definitions from agents directory
    if [ -d "${claudeConfigPath}/agents" ]; then
      for file in "${claudeConfigPath}/agents"/*; do
        if [ -f "$file" ]; then
          filename=$(${pkgs.coreutils}/bin/basename "$file")
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -sfn "$file" "${config.home.homeDirectory}/.claude/agents/$filename"
        fi
      done
    fi
  '';
}
