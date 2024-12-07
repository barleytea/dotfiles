{
  config,
  ...
}: let
  inherit (builtins) readFile;
  pwd = (import ../pwd.nix { inherit config; }).pwd;
in {
  programs.wezterm = {
    enable = true;
    extraConfig = readFile ./config/wezterm.lua;
  };

   xdg.configFile."wezterm" = {
    source = config.lib.file.mkOutOfStoreSymlink "${pwd}/wezterm/config";
  };
  xdg.configFile."wezterm/wezterm.lua" = {
    enable = false; # hack
  };
}
