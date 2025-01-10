{
  xdg.configFile."sheldon/plugins.toml".text = ''
    shell = "zsh"

    [plugins]

    [plugins.fast-syntax-highlighting]
    github = "zdharma/fast-syntax-highlighting"

    [plugins.zsh-autosuggestions]
    github = "zsh-users/zsh-autosuggestions"
  '';
}
