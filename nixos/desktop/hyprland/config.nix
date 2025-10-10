# Hyprland configuration file
{ config, pkgs, ... }:

{
  # Create Hyprland config file for users
  environment.etc."xdg/hypr/hyprland.conf".text = ''
    # Monitor configuration
    monitor=,preferred,auto,auto

    # Startup applications
    exec-once = waybar
    exec-once = dunst
    exec-once = hyprpaper
    exec-once = fcitx5
    exec-once = gammastep -l 35.6762:139.6503 -t 6500:3500
    exec-once = wl-paste --type text --watch cliphist store
    exec-once = wl-paste --type image --watch cliphist store

    # Environment variables
    env = XCURSOR_SIZE,24
    env = XCURSOR_THEME,Adwaita
    env = GTK_IM_MODULE,fcitx
    env = QT_IM_MODULE,fcitx
    env = XMODIFIERS,@im=fcitx
    env = INPUT_METHOD,fcitx
    env = WAYLAND_IM_MODULE,fcitx

    # Input configuration
    input {
        kb_layout = us
        kb_variant =
        kb_model =
        kb_options =
        kb_rules =

        follow_mouse = 1

        touchpad {
            natural_scroll = no
        }

        sensitivity = 0
    }

    # General settings
    general {
        gaps_in = 5
        gaps_out = 20
        border_size = 2
        col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
        col.inactive_border = rgba(595959aa)

        layout = dwindle
    }

    # Decoration
    decoration {
        rounding = 10
        
        blur {
            enabled = true
            size = 3
            passes = 1
        }

        shadow {
            enabled = true
            range = 4
            render_power = 3
            color = rgba(1a1a1aee)
        }
    }

    # Animations
    animations {
        enabled = yes

        bezier = myBezier, 0.05, 0.9, 0.1, 1.05

        animation = windows, 1, 7, myBezier
        animation = windowsOut, 1, 7, default, popin 80%
        animation = border, 1, 10, default
        animation = borderangle, 1, 8, default
        animation = fade, 1, 7, default
        animation = workspaces, 1, 6, default
    }

    # Layout configuration
    dwindle {
        pseudotile = yes
        preserve_split = yes
    }

    master {
        new_status = master
    }

    # Gestures
    gestures {
        workspace_swipe = off
    }

    # Key bindings
    $mainMod = SUPER

    # Basic bindings
    bind = $mainMod, Q, exec, alacritty
    bind = $mainMod, C, killactive,
    bind = $mainMod, M, exit,
    bind = $mainMod, E, exec, thunar
    bind = $mainMod, V, togglefloating,
    bind = $mainMod, Space, exec, wofi --show drun
    bind = $mainMod, P, pseudo,
    bind = $mainMod, J, togglesplit,

    # Move focus with mainMod + arrow keys
    bind = $mainMod, left, movefocus, l
    bind = $mainMod, right, movefocus, r
    bind = $mainMod, up, movefocus, u
    bind = $mainMod, down, movefocus, d

    # Move focus with mainMod + vim keys
    bind = $mainMod, h, movefocus, l
    bind = $mainMod, l, movefocus, r
    bind = $mainMod, k, movefocus, u
    bind = $mainMod, j, movefocus, d

    # Switch workspaces with mainMod + [0-9]
    bind = $mainMod, 1, workspace, 1
    bind = $mainMod, 2, workspace, 2
    bind = $mainMod, 3, workspace, 3
    bind = $mainMod, 4, workspace, 4
    bind = $mainMod, 5, workspace, 5
    bind = $mainMod, 6, workspace, 6
    bind = $mainMod, 7, workspace, 7
    bind = $mainMod, 8, workspace, 8
    bind = $mainMod, 9, workspace, 9
    bind = $mainMod, 0, workspace, 10

    # Move active window to a workspace with mainMod + SHIFT + [0-9]
    bind = $mainMod SHIFT, 1, movetoworkspace, 1
    bind = $mainMod SHIFT, 2, movetoworkspace, 2
    bind = $mainMod SHIFT, 3, movetoworkspace, 3
    bind = $mainMod SHIFT, 4, movetoworkspace, 4
    bind = $mainMod SHIFT, 5, movetoworkspace, 5
    bind = $mainMod SHIFT, 6, movetoworkspace, 6
    bind = $mainMod SHIFT, 7, movetoworkspace, 7
    bind = $mainMod SHIFT, 8, movetoworkspace, 8
    bind = $mainMod SHIFT, 9, movetoworkspace, 9
    bind = $mainMod SHIFT, 0, movetoworkspace, 10

    # Scroll through existing workspaces with mainMod + scroll
    bind = $mainMod, mouse_down, workspace, e+1
    bind = $mainMod, mouse_up, workspace, e-1

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = $mainMod, mouse:272, movewindow
    bindm = $mainMod, mouse:273, resizewindow

    # Screenshot bindings
    bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
    bind = SHIFT, Print, exec, grim - | wl-copy

    # Media keys
    bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
    bind = , XF86AudioLowerVolume, exec, pamixer -d 5
    bind = , XF86AudioMute, exec, pamixer -t
    bind = , XF86AudioPlay, exec, playerctl play-pause
    bind = , XF86AudioPause, exec, playerctl play-pause
    bind = , XF86AudioNext, exec, playerctl next
    bind = , XF86AudioPrev, exec, playerctl previous

    # Brightness keys
    bind = , XF86MonBrightnessUp, exec, brightnessctl set +10%
    bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

    # Lock screen
    bind = $mainMod, L, exec, hyprlock

    # Window rules
    windowrulev2 = float, class:^(pavucontrol)$
    windowrulev2 = float, class:^(blueman-manager)$
    windowrulev2 = float, class:^(nm-connection-editor)$
    windowrulev2 = float, class:^(firefox)$, title:^(Picture-in-Picture)$
    windowrulev2 = size 800 600, class:^(thunar)$
  '';
}