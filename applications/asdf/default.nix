let

asdfrc = ''
  legacy_version_file = yes
'';

in {
  home.file.".asdfrc".text = asdfrc;
}
