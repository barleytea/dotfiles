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
        go = "1.23.4";
        
        # [npm] 
        "npm:commitizen" = "latest";
        "npm:cz-git" = "latest";
        "npm:@redocly/cli" = "latest";
        "npm:corepack" = "latest";
        "npm:@anthropic-ai/claude-code" = "latest";
        "npm:@google/gemini-cli" = "latest";
      };
      
      settings = {
        # mise の動作設定
        experimental = true;
        plugin_autoupdate_last_check_duration = "7 days";
        trusted_config_paths = [
          config.home.homeDirectory
        ];
      };
    };
  };

  # mise 用の環境変数設定
  home.sessionVariables = {
    MISE_USE_TOML = "1";
    MISE_EXPERIMENTAL = "1";
  };
}
