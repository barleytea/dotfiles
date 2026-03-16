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
}
