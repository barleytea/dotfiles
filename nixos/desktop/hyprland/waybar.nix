# Waybar configuration
{ config, pkgs, ... }:

{
  # Create Waybar configuration files
  environment.etc."xdg/waybar/config".text = ''
    {
        "layer": "top",
        "position": "top",
        "height": 30,
        "spacing": 4,
        
        "modules-left": ["hyprland/workspaces", "hyprland/mode", "hyprland/scratchpad"],
        "modules-center": ["hyprland/window"],
        "modules-right": ["idle_inhibitor", "pulseaudio", "network", "cpu", "memory", "temperature", "backlight", "battery", "clock", "tray"],

        "hyprland/workspaces": {
            "disable-scroll": true,
            "all-outputs": true,
            "format": "{name}: {icon}",
            "format-icons": {
                "1": "",
                "2": "",
                "3": "",
                "4": "",
                "5": "",
                "urgent": "",
                "focused": "",
                "default": ""
            }
        },
        
        "hyprland/mode": {
            "format": "<span style=\"italic\">{}</span>"
        },
        
        "hyprland/scratchpad": {
            "format": "{icon} {count}",
            "show-empty": false,
            "format-icons": ["", ""],
            "tooltip": true,
            "tooltip-format": "{app}: {title}"
        },
        
        "hyprland/window": {
            "format": "{}",
            "max-length": 50
        },
        
        "idle_inhibitor": {
            "format": "{icon}",
            "format-icons": {
                "activated": "",
                "deactivated": ""
            }
        },
        
        "tray": {
            "spacing": 10
        },
        
        "clock": {
            "timezone": "Asia/Tokyo",
            "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
            "format-alt": "{:%Y-%m-%d}"
        },
        
        "cpu": {
            "format": "{usage}% ",
            "tooltip": false
        },
        
        "memory": {
            "format": "{}% "
        },
        
        "temperature": {
            "critical-threshold": 80,
            "format": "{temperatureC}°C {icon}",
            "format-icons": ["", "", ""]
        },
        
        "backlight": {
            "format": "{percent}% {icon}",
            "format-icons": ["", "", "", "", "", "", "", "", ""]
        },
        
        "battery": {
            "states": {
                "warning": 30,
                "critical": 15
            },
            "format": "{capacity}% {icon}",
            "format-charging": "{capacity}% ",
            "format-plugged": "{capacity}% ",
            "format-alt": "{time} {icon}",
            "format-icons": ["", "", "", "", ""]
        },
        
        "network": {
            "format-wifi": "{essid} ({signalStrength}%) ",
            "format-ethernet": "{ipaddr}/{cidr} ",
            "tooltip-format": "{ifname} via {gwaddr} ",
            "format-linked": "{ifname} (No IP) ",
            "format-disconnected": "Disconnected ⚠",
            "format-alt": "{ifname}: {ipaddr}/{cidr}"
        },
        
        "pulseaudio": {
            "format": "{volume}% {icon} {format_source}",
            "format-bluetooth": "{volume}% {icon} {format_source}",
            "format-bluetooth-muted": " {icon} {format_source}",
            "format-muted": " {format_source}",
            "format-source": "{volume}% ",
            "format-source-muted": "",
            "format-icons": {
                "headphone": "",
                "hands-free": "",
                "headset": "",
                "phone": "",
                "portable": "",
                "car": "",
                "default": ["", "", ""]
            },
            "on-click": "pavucontrol"
        }
    }
  '';

  environment.etc."xdg/waybar/style.css".text = ''
    * {
        border: none;
        border-radius: 0;
        font-family: "Hack Nerd Font", Roboto, Helvetica, Arial, sans-serif;
        font-size: 13px;
        min-height: 0;
    }

    window#waybar {
        background-color: rgba(43, 48, 59, 0.5);
        border-bottom: 3px solid rgba(100, 114, 125, 0.5);
        color: #ffffff;
        transition-property: background-color;
        transition-duration: .5s;
    }

    window#waybar.hidden {
        opacity: 0.2;
    }

    button {
        box-shadow: inset 0 -3px transparent;
        border: none;
        border-radius: 0;
    }

    button:hover {
        background: inherit;
        box-shadow: inset 0 -3px #ffffff;
    }

    #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #ffffff;
    }

    #workspaces button:hover {
        background: rgba(0, 0, 0, 0.2);
    }

    #workspaces button.focused {
        background-color: #64727D;
        box-shadow: inset 0 -3px #ffffff;
    }

    #workspaces button.urgent {
        background-color: #eb4d4b;
    }

    #mode {
        background-color: #64727D;
        border-bottom: 3px solid #ffffff;
    }

    #clock,
    #battery,
    #cpu,
    #memory,
    #disk,
    #temperature,
    #backlight,
    #network,
    #pulseaudio,
    #tray,
    #mode,
    #idle_inhibitor,
    #scratchpad,
    #mpd {
        padding: 0 10px;
        color: #ffffff;
    }

    #window,
    #workspaces {
        margin: 0 4px;
    }

    .modules-left > widget:first-child > #workspaces {
        margin-left: 0;
    }

    .modules-right > widget:last-child > #workspaces {
        margin-right: 0;
    }

    #clock {
        background-color: #64727D;
    }

    #battery {
        background-color: #ffffff;
        color: #000000;
    }

    #battery.charging, #battery.plugged {
        color: #ffffff;
        background-color: #26A65B;
    }

    @keyframes blink {
        to {
            background-color: #ffffff;
            color: #000000;
        }
    }

    #battery.critical:not(.charging) {
        background-color: #f53c3c;
        color: #ffffff;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
    }

    label:focus {
        background-color: #000000;
    }

    #cpu {
        background-color: #2ecc71;
        color: #000000;
    }

    #memory {
        background-color: #9b59b6;
    }

    #disk {
        background-color: #964B00;
    }

    #backlight {
        background-color: #90b1b1;
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
  '';
}