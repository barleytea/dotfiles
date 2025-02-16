{
  xdg.configFile."sheldon/plugins.toml".text = ''
    shell = "zsh"

    [plugins.zsh-defer]
    github = 'romkatv/zsh-defer'
    apply = ['source']

    [templates]
    defer = "{{ hooks | get: \"pre\" | nl }}{% for file in files %}zsh-defer source \"{{ file }}\"\n{% endfor %}{{ hooks | get: \"post\" | nl }}"

    [plugins.compinit]
    inline = 'autoload -Uz compinit && zsh-defer compinit'

    [plugins.colors]
    inline = 'autoload -Uz colors && zsh-defer colors'

    [plugins.fast-syntax-highlighting]
    github = "zdharma/fast-syntax-highlighting"
    apply = ['defer']

    [plugins.zsh-autosuggestions]
    github = "zsh-users/zsh-autosuggestions"
    apply = ['defer']
  '';
}
