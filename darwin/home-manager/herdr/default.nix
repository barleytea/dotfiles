{ ... }: {
  # herdr 設定（cmux と同様に読み込みのみのため symlink で管理可）
  xdg.configFile."herdr/config.toml" = {
    source = ./config.toml;
    force = true;
  };
}
