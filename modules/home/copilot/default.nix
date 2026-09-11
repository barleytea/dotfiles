{
  config,
  pkgs,
  ...
}: let
  dotfilesPath = "${config.home.homeDirectory}/git_repos/github.com/barleytea/dotfiles";
  claudeConfigPath = "${dotfilesPath}/modules/home/claude/config";

  # AGENTS.md の OS 別レンダリングは Claude / Gemini / Codex / Copilot で共有する。
  renderedAgents = import "${claudeConfigPath}/render-agents.nix" {inherit pkgs;};

  # VS Code の GitHub Copilot（Agent Host / ローカルエージェント）は
  # ~/.copilot/instructions/*.instructions.md をグローバル指示として読む。
  # frontmatter の applyTo: '**' で全ファイルに適用する。
  copilotInstructions = pkgs.writeText "copilot-instructions.md" ''
    ---
    name: 'dotfiles AGENTS.md'
    description: 'Personal AI agent principles shared with Claude Code / Gemini / Codex'
    applyTo: '**'
    ---
    ${builtins.readFile renderedAgents}
  '';
in {
  home.file.".copilot/instructions/dotfiles-agents.instructions.md".source = copilotInstructions;
}
