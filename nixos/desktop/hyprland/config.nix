# Hyprland configuration file
{ config, pkgs, ... }:

{
  # Create Hyprland config file for users
  environment.etc."xdg/hypr/hyprland.conf".text = ''
    # Monitor configuration
    monitor=,preferred,auto,auto

    # Startup applications
    exec-once = dunst
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
        gaps_in = 6
        gaps_out = 18
        border_size = 3
        resize_on_border = true
        allow_tearing = false
        col.active_border = rgba(b4befecc) rgba(cba6f7ff) 45deg
        col.inactive_border = rgba(1e1e2ecc)
        layout = dwindle
    }

    # Decoration
    decoration {
        rounding = 18
        active_opacity = 0.96
        inactive_opacity = 0.88

        blur {
            enabled = true
            size = 16
            passes = 3
            new_optimizations = true
            noise = 0.015
        }

        shadow {
            enabled = true
            range = 18
            render_power = 3
            color = rgba(0d0d1488)
        }
    }

    # Animations
    animations {
        enabled = yes
        bezier = smooth, 0.16, 1.00, 0.30, 1.00
        bezier = pop, 0.05, 0.80, 0.10, 1.05

        animation = windows, 1, 6, smooth
        animation = windowsOut, 1, 6, pop, popin 80%
        animation = border, 1, 5, smooth
        animation = borderangle, 1, 8, smooth
        animation = fade, 1, 5, smooth
        animation = workspaces, 1, 5, smooth
    }

    # Layout configuration
    dwindle {
        pseudotile = yes
        preserve_split = yes
        smart_split = true
        smart_resizing = true
    }

    master {
        new_status = master
    }

    misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
        focus_on_activate = true
        mouse_move_enables_dpms = true
    }

    # Key bindings
    $mainMod = SUPER

    # Basic bindings
    bind = $mainMod, Return, exec, alacritty
    bind = $mainMod SHIFT, Q, killactive,
    bind = $mainMod SHIFT, M, exit,
    bind = $mainMod SHIFT, E, exec, thunar
    bind = ALT SHIFT, V, exec, cliphist-menu
    bind = $mainMod SHIFT, V, togglefloating,
    bind = ALT, Space, exec, wofi --show drun
    bind = $mainMod SHIFT, P, pseudo,
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

    # Screenshot bindings (PrintScreen present)
    bind = , Print, exec, hyprshot area
    bind = SHIFT, Print, exec, hyprshot full

    # Screenshot bindings (alternatives when PrintScreen is unavailable)
    bind = ALT SHIFT, S, exec, hyprshot area
    bind = ALT SHIFT, D, exec, hyprshot full

    # Media keys (using pactl instead of pamixer due to build issues)
    bind = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
    bind = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
    bind = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
    bind = , XF86AudioPlay, exec, playerctl play-pause
    bind = , XF86AudioPause, exec, playerctl play-pause
    bind = , XF86AudioNext, exec, playerctl next
    bind = , XF86AudioPrev, exec, playerctl previous

    # Brightness keys
    bind = , XF86MonBrightnessUp, exec, brightnessctl set +10%
    bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

    # Lock screen
    bind = $mainMod SHIFT, L, exec, hyprlock

    # Window rules
    windowrulev2 = float, class:^(pavucontrol)$
    windowrulev2 = float, class:^(blueman-manager)$
    windowrulev2 = float, class:^(nm-connection-editor)$
    windowrulev2 = float, class:^(firefox)$, title:^(Picture-in-Picture)$
    windowrulev2 = size 800 600, class:^(thunar)$
  '';
}
