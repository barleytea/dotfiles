# Waybar configuration
{ config, pkgs, ... }:

{
  # Create Waybar configuration files
  environment.etc."xdg/waybar/config".text = ''
    {
        "layer": "top",
        "position": "top",
        "height": 32,
        "spacing": 4,
        "margin-top": 5,
        "margin-bottom": 0,
        "margin-left": 10,
        "margin-right": 10,
        
        "modules-left": ["hyprland/workspaces", "hyprland/mode", "hyprland/scratchpad", "hyprland/submap"],
        "modules-center": ["hyprland/window", "mpd"],
        "modules-right": ["custom/weather", "disk", "cpu", "memory", "temperature", "network", "bluetooth", "pulseaudio", "backlight", "battery", "custom/notification", "idle_inhibitor", "clock", "custom/power", "tray"],

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
            "max-length": 60,
            "separate-outputs": true
        },
        
        "hyprland/submap": {
            "format": " {}",
            "max-length": 8,
            "tooltip": false
        },
        
        "mpd": {
            "format": "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ",
            "format-disconnected": "Disconnected ",
            "format-stopped": "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ",
            "unknown-tag": "N/A",
            "interval": 2,
            "consume-icons": {
                "on": " "
            },
            "random-icons": {
                "off": "<span color=\"#f53c3c\"></span> ",
                "on": " "
            },
            "repeat-icons": {
                "on": " "
            },
            "single-icons": {
                "on": "1 "
            },
            "state-icons": {
                "paused": "",
                "playing": ""
            },
            "tooltip-format": "MPD (connected)",
            "tooltip-format-disconnected": "MPD (disconnected)"
        },
        
        "disk": {
            "interval": 30,
            "format": " {percentage_used}%",
            "path": "/",
            "tooltip": true,
            "tooltip-format": "Used: {used} / Total: {total}",
            "on-click": "thunar /"
        },
        
        "bluetooth": {
            "format": " {status}",
            "format-connected": " {device_alias}",
            "format-connected-battery": " {device_alias} {device_battery_percentage}%",
            "tooltip-format": "{controller_alias}\t{controller_address}\n\n{num_connections} connected",
            "tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}",
            "tooltip-format-enumerate-connected": "{device_alias}\t{device_address}",
            "tooltip-format-enumerate-connected-battery": "{device_alias}\t{device_address}\t{device_battery_percentage}%",
            "on-click": "blueman-manager"
        },
        
        "custom/weather": {
            "format": "{}",
            "tooltip": true,
            "interval": 1800,
            "exec": "curl -s 'https://wttr.in/Tokyo?format=1' 2>/dev/null || echo '🌤️ Weather unavailable'",
            "return-type": "",
            "on-click": "firefox https://weather.yahoo.co.jp/"
        },
        
        "custom/notification": {
            "tooltip": false,
            "format": "{icon}",
            "format-icons": {
                "notification": "<span foreground='red'><sup></sup></span>",
                "none": "",
                "dnd-notification": "<span foreground='red'><sup></sup></span>",
                "dnd-none": "",
                "inhibited-notification": "<span foreground='red'><sup></sup></span>",
                "inhibited-none": "",
                "dnd-inhibited-notification": "<span foreground='red'><sup></sup></span>",
                "dnd-inhibited-none": ""
            },
            "return-type": "json",
            "exec-if": "which swaync-client",
            "exec": "swaync-client -swb",
            "on-click": "swaync-client -t -sw",
            "on-click-right": "swaync-client -d -sw",
            "escape": true
        },
        
        "custom/power": {
            "format": "⏻",
            "tooltip": false,
            "on-click": "wlogout",
            "on-click-right": "hyprctl dispatch exit"
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
        background: linear-gradient(45deg, rgba(30, 30, 46, 0.9), rgba(49, 50, 68, 0.9));
        border-radius: 15px;
        border: 2px solid rgba(137, 180, 250, 0.3);
        color: #cdd6f4;
        transition-property: background-color;
        transition-duration: .5s;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
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