{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.mise = {
    enable = true;
    enableZshIntegration = true;

    globalConfig = {
      tools = {
        node = "lts";
        go = "1.24.5";
        python = "system";
        awscli = "latest";
        "npm:aws-cdk" = "latest";
        "npm:@redocly/cli" = "latest";
        "npm:corepack" = "latest";
        "npm:@google/gemini-cli" = "latest";
        "npm:reviewit" = "latest";
        "npm:vibe-kanban" = "latest";
        "npm:@openai/codex" = "latest";
        "npm:@github/copilot" = "latest";
        "npm:@vibe-kit/grok-cli" = "latest";
      };

      settings = {
        experimental = true;
        plugin_autoupdate_last_check_duration = "7 days";
        trusted_config_paths = [
          config.home.homeDirectory
        ];
      };

      # タスク定義でnpmグローバルインストールを実行
      tasks = {
        npm-commitizen = {
          description = "Install commitizen and cz-git globally";
          run = [
            "npm install -g commitizen cz-git"
          ];
        };
      };
    };
  };

  # mise 用の環境変数設定
  home.sessionVariables = {
    MISE_USE_TOML = "1";
    MISE_EXPERIMENTAL = "1";
  };
}
