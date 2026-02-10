{ pkgs, ... }:

let
  configYaml = ''
    gui:
      language: 'ja'
      showRandomTip: false

    git:
      pagers:
        - pager: delta --dark --paging=never

    os:
      editCommand: 'nvim'

    confirmOnQuit: false

    customCommands:
      - command: git cz
        context: files
        output: terminal
        key: C
        description: 'Commit with commitizen (git-cz)'
  '';
in {
  home.file.".config/lazygit/config.yml".text = configYaml;
}
