{ pkgs, ... }:

let
  username = if builtins.getEnv "USER" == "runner" then builtins.getEnv "USER" else "miyoshi_s";
  # macOS only
  home = "/Users/${username}";
in {
  inherit username home;
}
