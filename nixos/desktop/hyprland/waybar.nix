# Waybar configuration
{ config, pkgs, ... }:

{
  # Create Waybar configuration files
  environment.etc."xdg/waybar/config".text = ''
    {
        "layer": "top",
        "position": "top",
        "height": 36,
        "margin": "10 24 0 24",
        "spacing": 10,
        "gtk-layer-shell": true,
        "modules-left": ["custom/logo", "custom/launcher", "hyprland/workspaces", "hyprland/window"],
        "modules-center": ["custom/nowplaying"],
        "modules-right": ["group/system", "group/status", "clock", "tray", "custom/power"],

        "custom/logo": {
            "format": "{}",
            "exec": "echo ",
            "interval": 0,
            "tooltip": "Hyprland"
        },

        "custom/launcher": {
            "format": "󰍉",
            "tooltip": "アプリケーションを開く",
            "interval": 0,
            "on-click": "wofi --show drun &",
            "on-click-right": "wofi --show run &"
        },

        "hyprland/workspaces": {
            "disable-scroll": true,
            "all-outputs": true,
            "active-only": false,
            "sort-by-number": true,
            "format": "{name}",
            "persistent-workspaces": {
                "*": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            }
        },

        "hyprland/window": {
            "format": "{}",
            "max-length": 48,
            "separate-outputs": true,
            "empty-format": "Ready to flow",
            "rewrite": {
                "(.*) — Mozilla Firefox": "  $1",
                "(.*) - Visual Studio Code": "  $1",
                "(.*) - Alacritty": "  $1"
            }
        },

        "custom/nowplaying": {
            "exec": "playerctl metadata --format '{{ artist }} — {{ title }}' 2>/dev/null || echo Nothing playing",
            "interval": 5,
            "tooltip": true,
            "on-click": "playerctl play-pause",
            "on-scroll-up": "playerctl next",
            "on-scroll-down": "playerctl previous",
            "format": "󰎈  {}",
            "max-length": 48
        },

        "group/system": {
            "orientation": "horizontal",
            "modules": ["pulseaudio", "cpu", "temperature", "memory"]
        },

        "group/status": {
            "orientation": "horizontal",
            "modules": ["network", "battery", "custom/notification"]
        },

        "tray": {
            "icon-size": 18,
            "spacing": 12
        },

        "pulseaudio": {
            "format": "{icon} {volume:>3}%",
            "format-muted": "󰝟 mute",
            "format-icons": {
                "headphones": "󰋋",
                "handsfree": "󰋎",
                "headset": "󰋎",
                "phone": "󰄜",
                "portable": "󰏴",
                "car": "󰄫",
                "default": ["󰕾", "󰖀", "󰕿"]
            },
            "scroll-step": 3,
            "on-click": "pavucontrol"
        },

        "network": {
            "format-wifi": "{essid}  {signalStrength:>3}%",
            "format-ethernet": "{ifname}",
            "format-disconnected": "offline",
            "tooltip-format": "{ifname} via {gwaddr}\\n{ipaddr}/{cidr}",
            "on-click": "nm-connection-editor"
        },

        "battery": {
            "format": "{icon} {capacity:>3}%",
            "format-charging": "󰂄 {capacity:>3}%",
            "format-plugged": "󰂄 {capacity:>3}%",
            "format-alt": "{time} remaining",
            "states": {
                "warning": 30,
                "critical": 15
            },
            "format-icons": ["󰁻","󰁼","󰁾","󰂀","󰂂","󰁹"]
        },

        "cpu": {
            "format": "󰍛 {usage:>3}%",
            "tooltip": false
        },

        "memory": {
            "format": "󰘚 {percentage:>3}%",
            "tooltip": false
        },

        "temperature": {
            "critical-threshold": 80,
            "format": "󰍛 {temperatureC}󰔄",
            "format-icons": ["󰔄"]
        },

        "custom/notification": {
            "tooltip": false,
            "format": "{icon}",
            "format-icons": {
                "notification": "󰂚",
                "none": "󰂜",
                "dnd-notification": "󰂛",
                "dnd-none": "󰂛",
                "inhibited-notification": "󰂛",
                "inhibited-none": "󰂛",
                "dnd-inhibited-notification": "󰂛",
                "dnd-inhibited-none": "󰂛"
            },
            "return-type": "json",
            "exec-if": "which swaync-client",
            "exec": "swaync-client -swb",
            "on-click": "swaync-client -t -sw",
            "on-click-right": "swaync-client -d -sw",
            "escape": true
        },

        "clock": {
            "timezone": "Asia/Tokyo",
            "format": "{:%a %d · %H:%M}",
            "format-alt": "{:%Y-%m-%d}",
            "tooltip-format": "<b>{:%A, %B %d}</b>\n<tt><small>{calendar}</small></tt>"
        },

        "custom/power": {
            "format": "󰤆",
            "tooltip": false,
            "on-click": "wlogout",
            "on-click-right": "hyprctl dispatch exit"
        }
    }
  '';

  environment.etc."xdg/waybar/style.css".text = ''
    @define-color base rgba(16, 18, 28, 0.62);
    @define-color surface rgba(26, 28, 40, 0.78);
    @define-color surface-alt rgba(38, 40, 56, 0.82);
    @define-color overlay rgba(255, 255, 255, 0.08);
    @define-color text #e7e9ff;
    @define-color muted rgba(231, 233, 255, 0.58);
    @define-color accent #89dceb;
    @define-color accent-alt #f5c2e7;
    @define-color warn #f9e2af;
    @define-color danger #f38ba8;

    * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "Inter", "Noto Sans JP", sans-serif;
        font-size: 13px;
        min-height: 0;
        color: @text;
    }

    window#waybar {
        background: linear-gradient(135deg, rgba(24, 26, 38, 0.82), rgba(16, 18, 28, 0.68));
        border-radius: 22px;
        border: 1px solid @overlay;
        padding: 12px 20px;
        margin: 0;
        box-shadow: 0 18px 48px rgba(4, 6, 14, 0.6);
        transition: opacity 0.2s ease;
    }

    window#waybar.hidden {
        opacity: 0.1;
    }

    .modules-left > widget,
    .modules-center > widget,
    .modules-right > widget {
        margin: 0 8px;
    }

    .modules-left > widget:first-child,
    .modules-center > widget:first-child,
    .modules-right > widget:first-child {
        margin-left: 0;
    }

    .modules-left > widget:last-child,
    .modules-center > widget:last-child,
    .modules-right > widget:last-child {
        margin-right: 0;
    }

    #custom-logo {
        font-size: 18px;
        padding: 0 10px;
        color: @accent;
    }

    #custom-launcher {
        background: @surface;
        border-radius: 16px;
        border: 1px solid @overlay;
        padding: 6px 14px;
        font-size: 15px;
        transition: background 0.25s ease, box-shadow 0.25s ease;
    }

    #custom-launcher:hover {
        background: @surface-alt;
        box-shadow: 0 4px 16px rgba(137, 220, 235, 0.25);
    }

    #workspaces {
        background: @surface;
        border-radius: 18px;
        border: 1px solid @overlay;
        padding: 4px 10px;
    }

    #workspaces button {
        background: rgba(137, 220, 235, 0.06);
        padding: 6px 16px;
        margin: 0 5px;
        border-radius: 12px;
        transition: all 0.2s ease;
        color: rgba(231, 233, 255, 0.55);
        font-weight: 500;
        border: 1px solid transparent;
        border-bottom: 2px solid transparent;
        letter-spacing: 0.03em;
    }

    #workspaces button.active,
    #workspaces button.focused {
        background: linear-gradient(130deg, rgba(137, 220, 235, 0.75), rgba(203, 166, 247, 0.78));
        color: #0b0d1a;
        box-shadow: 0 8px 22px rgba(137, 220, 235, 0.45);
        border: 1px solid rgba(137, 220, 235, 0.9);
        border-bottom: 2px solid rgba(137, 220, 235, 0.95);
        font-weight: 700;
    }

    #workspaces button.urgent {
        background: rgba(243, 139, 168, 0.38);
        color: #1a1a1a;
    }

    #workspaces button:hover {
        color: @text;
        background: rgba(137, 220, 235, 0.22);
    }

    #hyprland-window,
    #custom-nowplaying,
    #clock,
    #tray,
    #custom-power {
        background: @surface;
        border-radius: 18px;
        border: 1px solid @overlay;
        padding: 0 16px;
        min-height: 30px;
    }

    #hyprland-window {
        font-weight: 700;
        border-left: 4px solid rgba(137, 220, 235, 0.85);
        background: linear-gradient(135deg, rgba(137, 220, 235, 0.22), rgba(245, 194, 231, 0.18));
        color: @text;
        padding: 0 20px;
        letter-spacing: 0.02em;
    }

    #custom-nowplaying {
        background: linear-gradient(135deg, rgba(137, 220, 235, 0.28), rgba(245, 194, 231, 0.24));
        color: @text;
        padding: 0 20px;
        margin: 0 12px;
    }

    #clock {
        font-weight: 600;
        color: @accent;
        padding: 0 16px;
    }

    #tray {
        padding: 0 12px;
        margin-left: 6px;
    }

    #custom-power {
        color: @danger;
        background: rgba(243, 139, 168, 0.2);
        transition: background 0.2s ease, box-shadow 0.2s ease;
        margin-left: 10px;
    }

    #custom-power:hover {
        background: rgba(243, 139, 168, 0.32);
        box-shadow: 0 4px 16px rgba(243, 139, 168, 0.28);
    }

    #group-system,
    #group-status {
        background: transparent;
        border: none;
        padding: 4px 6px;
        margin: 0 6px;
    }

    #group-system > widget,
    #group-status > widget {
        background: transparent;
        border: none;
        padding: 0;
        margin: 0;
        min-height: 30px;
    }

    #group-system > widget:first-child,
    #group-status > widget:first-child {
        margin-left: 0;
    }

    #group-system > widget:last-child,
    #group-status > widget:last-child {
        margin-right: 0;
    }

    #pulseaudio,
    #network,
    #cpu,
    #memory,
    #temperature {
        background: linear-gradient(135deg, rgba(137, 220, 235, 0.18), rgba(245, 194, 231, 0.16));
        border-radius: 16px;
        border: 1px solid @overlay;
        padding: 0 16px;
        margin: 0 8px;
        min-height: 32px;
        box-shadow: 0 10px 24px rgba(10, 12, 24, 0.28);
    }

    #pulseaudio.muted {
        color: @warn;
        opacity: 0.65;
    }

    #battery.warning {
        color: @warn;
    }

    #battery.critical {
        color: @danger;
        animation: battery-pulse 1.6s ease-in-out infinite;
    }

    #battery.charging {
        color: @accent;
    }

    #network.disconnected {
        color: @danger;
    }

    #cpu,
    #memory {
        color: @accent;
    }

    #temperature {
        color: @accent-alt;
    }

    #custom-notification {
        color: @muted;
    }

    tooltip {
        background: rgba(22, 24, 34, 0.96);
        border-radius: 12px;
        border: 1px solid @overlay;
        padding: 6px 10px;
    }

    tooltip label {
        color: @text;
    }

    @keyframes battery-pulse {
        0% { color: @danger; }
        50% { color: rgba(243, 139, 168, 0.6); }
        100% { color: @danger; }
    }
  '';
}
