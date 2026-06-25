{
  config,
  pkgs,
  lib,
  ...
}: {
  home.file.".local/bin/difit-cmux" = {
    text = builtins.readFile ../scripts/difit-auto-detect.sh;
    executable = true;
  };

  home.file.".local/bin/difit-cmux-hook" = {
    text = builtins.readFile ../scripts/difit-cmux-hook.sh;
    executable = true;
  };

  home.file.".local/bin/cmux-workspace" = {
    text = builtins.readFile ../scripts/cmux-workspace.sh;
    executable = true;
  };

  # cmux settings（Dracula カラーパレット、サイドバー表示設定）
  # cmux は settings.json を読み込みのみで上書きしないため symlink で管理可
  xdg.configFile."cmux/settings.json" = {
    source = ./settings.json;
    force = true;
  };
}
