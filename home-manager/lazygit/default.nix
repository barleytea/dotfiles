{ pkgs, ... }:

let
  configYaml = ''
    gui:
      language: 'ja'
      showRandomTip: false

    git:
      paging:
        pager: delta --dark --paging=never

    os:
      editCommand: 'nvim'

    confirmOnQuit: false
  '';
in {
  home.file.".config/lazygit/config.yml".text = configYaml;
}
