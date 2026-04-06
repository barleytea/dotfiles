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
        python = "3.13";
        # Pin to a concrete release; "latest" URL 404s in CI on macOS runners.
        awscli = "2.22.28";
        jujutsu = "latest";
        # Pin npm CLIs so CI remains reproducible and npm min-release-age stays effective.
        "npm:aws-cdk" = "2.1034.0";
        "npm:@redocly/cli" = "1.34.4";
        "npm:corepack" = "0.33.0";
        "npm:@google/gemini-cli" = "0.1.7";
        "npm:reviewit" = "1.1.9";
        "npm:vibe-kanban" = "0.0.104";
        "npm:@openai/codex" = "0.114.0";
        "npm:@vibe-kit/grok-cli" = "0.0.34";
        "npm:ccusage" = "18.0.10";
        "npm:difit" = "3.1.15";
        "npm:@aikidosec/safe-chain" = "1.4.4";
        "pipx:pre-commit" = "latest";
      };

      settings = {
        experimental = true;
        plugin_autoupdate_last_check_duration = "7 days";
        trusted_config_paths = [
          config.home.homeDirectory
        ];
        python = {
          precompiled_flavor = "install_only";
        };
      };

      # タスク定義でnpmグローバルインストールを実行
      tasks = {
        npm-commitizen = {
          description = "Install commitizen and cz-git globally";
          run = [
            "aikido-npm install -g commitizen cz-git"
          ];
        };
        copilot-install = {
          description = "Install GitHub Copilot CLI via official install script";
          run = [
            "curl -fsSL https://gh.io/copilot-install | bash"
          ];
        };
        claude-install = {
          description = "Install Claude Code CLI via official install script";
          run = [
            "curl -fsSL https://claude.ai/install.sh | bash"
          ];
        };
        pre-commit-init = {
          description = "Install pre-commit hooks";
          run = [
            "pre-commit install"
          ];
        };
        safe-chain-setup = {
          description = "Set up aikido safe-chain (CA cert + npm proxy)";
          run = [
            "safe-chain setup"
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
