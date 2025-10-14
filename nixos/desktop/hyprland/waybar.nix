# Waybar configuration
{ config, pkgs, ... }:

{
  # Create Waybar configuration files
  environment.etc."xdg/waybar/config".text = ''
    {
        "layer": "top",
        "position": "top",
        "height": 36,
        "spacing": 8,
        "margin": "12 20 0 20",
        "modules-left": ["custom/logo", "custom/launcher", "hyprland/workspaces"],
        "modules-center": ["hyprland/window"],
        "modules-right": ["custom/nowplaying", "custom/weather", "pulseaudio", "network", "backlight", "battery", "cpu", "memory", "temperature", "idle_inhibitor", "custom/notification", "clock", "tray", "custom/power"],

        "custom/logo": {
            "format": "{}",
            "exec": "echo ",
            "interval": 0,
            "tooltip": false
        },

        "custom/launcher": {
            "format": "󰍉",
            "tooltip": "Launch applications",
            "interval": 0,
            "on-click": "wofi --show drun &",
            "on-click-right": "wofi --show run &"
        },

        "hyprland/workspaces": {
            "disable-scroll": true,
            "all-outputs": true,
            "active-only": false,
            "sort-by-number": true,
            "format": "{icon}",
            "persistent-workspaces": {
                "*": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            },
            "format-icons": {
                "urgent": "",
                "focused": "",
                "default": ""
            }
        },

        "hyprland/window": {
            "format": "{}",
            "max-length": 40,
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

        "custom/weather": {
            "format": "{}",
            "tooltip": true,
            "interval": 1200,
            "exec": "curl -fs 'https://wttr.in/Tokyo?format=%c %t' || echo Weather N/A",
            "return-type": "string",
            "on-click": "firefox https://weather.yahoo.co.jp/"
        },

        "tray": {
            "icon-size": 18,
            "spacing": 10
        },

        "pulseaudio": {
            "format": "{icon} {volume}%",
            "format-muted": "󰝟  mute",
            "format-icons": {
                "headphones": "󰋋",
                "handsfree": "󰋎",
                "headset": "󰋎",
                "phone": "󰄜",
                "portable": "󰏴",
                "car": "󰄫",
                "default": ["󰖀", "󰕾", "󰕿"]
            },
            "scroll-step": 3,
            "on-click": "pavucontrol"
        },

        "network": {
            "format-wifi": "󰖩  {essid}",
            "format-ethernet": "󰈀  {ifname}",
            "format-disconnected": "󰖪  offline",
            "tooltip-format": "{ifname} via {gwaddr}\\n{ipaddr}/{cidr}",
            "on-click": "nm-connection-editor"
        },

        "backlight": {
            "format": "󰃜  {percent}%",
            "format-icons": ["󰃜"]
        },

        "battery": {
            "format": "{icon} {capacity}%",
            "format-charging": "󰂄 {capacity}%",
            "format-plugged": "󰂄 {capacity}%",
            "format-alt": "{time} remaining",
            "states": {
                "warning": 30,
                "critical": 15
            },
            "format-icons": ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
        },

        "cpu": {
            "format": "󰍛 {usage}%",
            "tooltip": false
        },

        "memory": {
            "format": "󰍛 {percentage}%",
            "tooltip": false
        },

        "temperature": {
            "critical-threshold": 80,
            "format": "󰔄 {temperatureC}°",
            "format-icons": ["󰔄"]
        },

        "idle_inhibitor": {
            "format": "{icon}",
            "format-icons": {
                "activated": "󰌵",
                "deactivated": "󰌶"
            }
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
            "format": "{:%H:%M}",
            "format-alt": "{:%a %b %d}",
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
    @define-color base rgba(14, 16, 26, 0.72);
    @define-color mantle rgba(24, 25, 36, 0.65);
    @define-color surface rgba(30, 30, 46, 0.82);
    @define-color overlay #6c7086;
    @define-color text #cdd6f4;
    @define-color accent #cba6f7;
    @define-color accent2 #74c7ec;
    @define-color accent3 #f2cdcd;

    * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font", "Inter", "Noto Sans JP", sans-serif;
        font-size: 13px;
        min-height: 0;
        color: @text;
    }

    window#waybar {
        background: linear-gradient(120deg, rgba(25, 26, 39, 0.88), rgba(17, 18, 28, 0.72));
        border-radius: 22px;
        border: 1px solid rgba(180, 190, 254, 0.25);
        padding: 12px 18px;
        margin: 0;
        box-shadow: 0 18px 48px rgba(8, 9, 15, 0.6);
        backdrop-filter: blur(22px);
    }

    window#waybar.hidden {
        opacity: 0.12;
    }

    .modules-left > widget,
    .modules-center > widget,
    .modules-right > widget {
        margin: 0 8px;
    }

    #custom-logo {
        font-size: 16px;
        padding: 0 10px;
        color: @accent;
    }

    #custom-logo:hover {
        color: @accent2;
    }

    #custom-launcher {
        background: rgba(203, 166, 247, 0.18);
        border-radius: 14px;
        padding: 6px 12px;
        font-size: 15px;
        transition: all 0.25s ease;
    }

    #custom-launcher:hover {
        background: rgba(203, 166, 247, 0.32);
        box-shadow: 0 0 12px rgba(203, 166, 247, 0.35);
    }

    #workspaces {
        background: rgba(30, 32, 48, 0.75);
        border-radius: 16px;
        padding: 4px 8px;
    }

    #workspaces button {
        background: transparent;
        padding: 4px 10px;
        margin: 0 2px;
        border-radius: 12px;
        transition: all 0.25s ease;
        color: rgba(205, 214, 244, 0.45);
    }

    #workspaces button.focused {
        background: rgba(203, 166, 247, 0.35);
        color: @text;
        box-shadow: 0 0 10px rgba(203, 166, 247, 0.35);
    }

    #workspaces button.urgent {
        background: rgba(244, 184, 228, 0.4);
        color: #ffffff;
    }

    #workspaces button:hover {
        color: @text;
        background: rgba(148, 226, 213, 0.28);
    }

    #hyprland-window {
        padding: 0 18px;
        border-radius: 16px;
        background: rgba(30, 32, 48, 0.6);
        color: @text;
        font-weight: 500;
    }

    #custom-nowplaying {
        max-width: 360px;
        padding: 0 16px;
        border-radius: 16px;
        background: rgba(148, 226, 213, 0.14);
        color: @text;
    }

    #custom-weather {
        padding: 0 12px;
        border-radius: 12px;
        background: rgba(116, 199, 236, 0.18);
    }

    #pulseaudio,
    #network,
    #backlight,
    #battery,
    #cpu,
    #memory,
    #temperature,
    #idle_inhibitor,
    #custom-notification,
    #clock {
        background: rgba(35, 37, 53, 0.68);
        border-radius: 12px;
        padding: 0 10px;
    }

    #clock {
        font-weight: 600;
        color: @accent;
    }

    #pulseaudio.muted {
        background: rgba(249, 226, 175, 0.28);
        color: @accent3;
    }

    #battery.warning {
        color: #f9e2af;
    }

    #battery.critical {
        background: rgba(235, 160, 172, 0.28);
        color: #f38ba8;
    }

    #battery.charging {
        color: #94e2d5;
    }

    #cpu,
    #memory {
        color: @accent2;
    }

    #temperature {
        color: @accent3;
    }

    #custom-notification,
    #idle_inhibitor {
        color: @accent2;
    }

    #tray {
        background: rgba(30, 32, 48, 0.65);
        border-radius: 14px;
        padding: 0 10px;
    }

    #custom-power {
        color: #f38ba8;
        padding: 0 16px;
        border-radius: 16px;
        background: rgba(244, 219, 226, 0.18);
        transition: all 0.2s ease;
    }

    #custom-power:hover {
        background: rgba(243, 139, 168, 0.32);
        box-shadow: 0 0 10px rgba(243, 139, 168, 0.28);
    }

    tooltip {
        background: rgba(24, 25, 38, 0.96);
        border-radius: 12px;
        border: 1px solid rgba(180, 190, 254, 0.3);
        padding: 6px 10px;
    }

    tooltip label {
        color: @text;
    }

    #network {
        background-color: #2980b9;
    }

    #network.disconnected {
        background-color: #f53c3c;
    }

    #pulseaudio {
        background-color: #f1c40f;
        color: #000000;
    }

    #pulseaudio.muted {
        background-color: #90b1b1;
        color: #2a5c45;
    }

    #temperature {
        background-color: #f0932b;
    }

    #temperature.critical {
        background-color: #eb4d4b;
    }

    #tray {
        background-color: #2980b9;
    }

    #tray > .passive {
        -gtk-icon-effect: dim;
    }

    #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #eb4d4b;
    }

    #idle_inhibitor {
        background-color: #2d3436;
    }

    #idle_inhibitor.activated {
        background-color: #ecf0f1;
        color: #2d3436;
    }

    #scratchpad {
        background: rgba(0, 0, 0, 0.2);
    }

    #scratchpad.empty {
        background-color: transparent;
    }

    #custom-weather {
        background-color: #fab387;
        color: #1e1e2e;
        border-radius: 10px;
        padding: 0 10px;
        margin: 0 5px;
    }

    #custom-power {
        background-color: #f38ba8;
        color: #1e1e2e;
        border-radius: 10px;
        padding: 0 10px;
        margin: 0 5px;
        font-weight: bold;
    }

    #custom-power:hover {
        background-color: #f9e2af;
    }

    #custom-notification {
        background-color: #a6e3a1;
        color: #1e1e2e;
        border-radius: 10px;
        padding: 0 10px;
        margin: 0 5px;
    }

    #disk {
        background-color: #94e2d5;
        color: #1e1e2e;
        border-radius: 10px;
        padding: 0 10px;
        margin: 0 5px;
    }

    #bluetooth {
        background-color: #89b4fa;
        color: #1e1e2e;
        border-radius: 10px;
        padding: 0 10px;
        margin: 0 5px;
    }

    #bluetooth.disabled {
        background-color: #6c7086;
    }

    #bluetooth.off {
        background-color: #6c7086;
    }

    #mpd {
        background-color: #cba6f7;
        color: #1e1e2e;
        border-radius: 10px;
        padding: 0 10px;
        margin: 0 5px;
    }

    #mpd.disconnected {
        background-color: #6c7086;
    }

    #mpd.stopped {
        background-color: #6c7086;
    }

    #mpd.paused {
        background-color: #f2cdcd;
        color: #1e1e2e;
    }

    /* Enhanced module styling */
    #workspaces button {
        padding: 5px 10px;
        background: rgba(137, 180, 250, 0.1);
        color: #cdd6f4;
        border-radius: 10px;
        margin: 0 2px;
        transition: all 0.3s ease;
    }

    #workspaces button:hover {
        background: rgba(137, 180, 250, 0.3);
    }

    #workspaces button.active {
        background: linear-gradient(45deg, #89b4fa, #b4befe);
        color: #1e1e2e;
        font-weight: bold;
    }

    #window {
        background: rgba(49, 50, 68, 0.8);
        border-radius: 10px;
        padding: 0 15px;
        margin: 0 10px;
        font-style: italic;
    }
  '';
}
