let

  inherit (builtins) readFile;

in {
  home.file."justfile".text = readFile ../../justfile;
}
