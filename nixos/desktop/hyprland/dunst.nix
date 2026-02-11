# Dunst notification configuration
{ config, pkgs, ... }:

{
  # Create dunst configuration
  environment.etc."xdg/dunst/dunstrc".text = ''
    [global]
        monitor = 0
        follow = mouse
        geometry = "300x5-30+50"
        indicate_hidden = yes
        shrink = no
        transparency = 0
        notification_height = 0
        separator_height = 2
        padding = 8
        horizontal_padding = 8
        frame_width = 2
        frame_color = "#89b4fa"
        separator_color = frame
        sort = yes
        idle_threshold = 120
        font = Hack Nerd Font 10
        line_height = 0
        markup = full
        format = "<b>%s</b>\n%b"
        alignment = left
        show_age_threshold = 60
        word_wrap = yes
        ellipsize = middle
        ignore_newline = no
        stack_duplicates = true
        hide_duplicate_count = false
        show_indicators = yes
        icon_position = left
        max_icon_size = 32
        icon_path = /usr/share/icons/gnome/16x16/status/:/usr/share/icons/gnome/16x16/devices/
        sticky_history = yes
        history_length = 20
        dmenu = /usr/bin/dmenu -p dunst:
        browser = /usr/bin/firefox -new-tab
        always_run_script = true
        title = Dunst
        class = Dunst
        startup_notification = false
        verbosity = mesg
        corner_radius = 10
        mouse_left_click = close_current
        mouse_middle_click = do_action
        mouse_right_click = close_all

    [experimental]
        per_monitor_dpi = false

    [shortcuts]
        close = ctrl+space
        close_all = ctrl+shift+space
        history = ctrl+grave
        context = ctrl+shift+period

    [urgency_low]
        background = "#1e1e2e"
        foreground = "#cdd6f4"
        timeout = 10

    [urgency_normal]
        background = "#1e1e2e"
        foreground = "#cdd6f4"
        timeout = 10

    [urgency_critical]
        background = "#1e1e2e"
        foreground = "#f38ba8"
        frame_color = "#f38ba8"
        timeout = 0

    [play_sound]
        summary = "*"
        script = /usr/share/sounds/freedesktop/stereo/message-new-instant.oga
  '';
}
