# Hyprlock and hypridle configuration
{ config, pkgs, ... }:

{
  # Create hyprlock configuration
  environment.etc."xdg/hypr/hyprlock.conf".text = ''
    general {
        disable_loading_bar = true
        grace = 300
        hide_cursor = true
        no_fade_in = false
    }

    background {
        monitor =
        path = /usr/share/backgrounds/nixos/nix-wallpaper-simple-dark-gray.png
        blur_passes = 3
        blur_size = 8
    }

    input-field {
        monitor =
        size = 200, 50
        position = 0, -80
        dots_center = true
        fade_on_empty = false
        font_color = rgb(202, 211, 245)
        inner_color = rgb(91, 96, 120)
        outer_color = rgb(24, 25, 38)
        outline_thickness = 5
        placeholder_text = <span foreground="##cad3f5">Password...</span>
        shadow_passes = 2
    }

    label {
        monitor =
        text = cmd[update:1000] echo "$TIME"
        color = rgba(200, 200, 200, 1.0)
        font_size = 55
        font_family = Hack Nerd Font
        position = 0, 80
        halign = center
        valign = center
    }

    label {
        monitor =
        text = Hi there, $USER
        color = rgba(200, 200, 200, 1.0)
        font_size = 20
        font_family = Hack Nerd Font
        position = 0, 0
        halign = center
        valign = center
    }
  '';

  # Create hypridle configuration
  environment.etc."xdg/hypr/hypridle.conf".text = ''
    general {
        lock_cmd = pidof hyprlock || hyprlock
        before_sleep_cmd = loginctl lock-session
        after_sleep_cmd = hyprctl dispatch dpms on
    }

    listener {
        timeout = 150
        on-timeout = brightnessctl -s set 10
        on-resume = brightnessctl -r
    }

    listener {
        timeout = 300
        on-timeout = loginctl lock-session
    }

    listener {
        timeout = 330
        on-timeout = hyprctl dispatch dpms off
        on-resume = hyprctl dispatch dpms on
    }

    listener {
        timeout = 1800
        on-timeout = systemctl suspend
    }
  '';
}