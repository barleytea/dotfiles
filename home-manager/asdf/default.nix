let

asdfrc = ''
  legacy_version_file = yes
'';

in {
  xdg.configFile."asdf/asdfrc".text = asdfrc;
}
