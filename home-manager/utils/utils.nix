{ pkgs, ... }:

let
  username = if builtins.getEnv "USER" == "runner" then builtins.getEnv "USER" else "miyoshi_s";
  home = if builtins.currentSystem == "x86_64-linux" then "/home/${username}" else "/Users/${username}";
in {
  inherit username home;
}
