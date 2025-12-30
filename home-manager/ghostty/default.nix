{
  config,
  ...
}: let
  pwd = (import ../pwd.nix { inherit config; }).pwd;
in {
  xdg.configFile."ghostty" = {
    source = config.lib.file.mkOutOfStoreSymlink "${pwd}/ghostty/config";
  };
}
