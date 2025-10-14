# Albert configuration for GNOME
{ config, pkgs, ... }:

{
  # GNOME-specific Albert settings
  programs.dconf.profiles.user.databases = [{
    lockAll = false;
    settings = {
      # Custom keyboard shortcuts for Albert
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Alt>space";
        command = "albert toggle";
        name = "Albert Launcher";
      };
      
      # Enable custom keybindings
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];
      };
      
      # Disable GNOME's default Super key behavior to avoid conflicts
      "org/gnome/mutter" = {
        overlay-key = "";
      };
    };
  }];

  # Albert autostart for GNOME
  environment.etc."xdg/autostart/albert.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Albert
    Comment=Keyboard launcher
    Exec=albert
    Icon=albert
    Terminal=false
    NoDisplay=true
    X-GNOME-Autostart-enabled=true
    StartupNotify=false
  '';
}
