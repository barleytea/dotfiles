# Wofi configuration
{ config, pkgs, ... }:

{
  # Create wofi configuration files
  environment.etc."xdg/wofi/config".text = ''
    width=720
    height=480
    location=center
    show=drun
    prompt=Search…
    filter_rate=140
    allow_markup=true
    no_actions=true
    halign=center
    orientation=vertical
    content_halign=fill
    insensitive=true
    allow_images=true
    image_size=40
    gtk_dark=true
    hide_scrollbar=true
    matching=fuzzy
  '';

  environment.etc."xdg/wofi/style.css".text = ''
    @define-color base rgba(17, 17, 27, 0.90);
    @define-color surface rgba(30, 30, 46, 0.85);
    @define-color text #cdd6f4;
    @define-color overlay #74c7ec;
    @define-color accent #cba6f7;

    window {
        margin: 0;
        padding: 14px 18px 18px 18px;
        border: 1px solid rgba(180, 190, 254, 0.3);
        background-color: @base;
        border-radius: 22px;
        box-shadow: 0 18px 60px rgba(10, 10, 20, 0.55);
        font-family: "JetBrainsMono Nerd Font", "Inter", "Noto Sans JP";
    }

    #input {
        margin: 0 0 16px 0;
        padding: 12px 16px;
        border: none;
        color: @text;
        background-color: rgba(49, 50, 68, 0.8);
        border-radius: 16px;
        font-size: 15px;
        caret-color: @accent;
    }

    #prompt {
        color: @overlay;
        font-weight: 600;
        margin-right: 8px;
    }

    #inner-box {
        border-radius: 16px;
        background-color: transparent;
    }

    #outer-box {
        background-color: transparent;
        border: none;
    }

    #scroll {
        border-radius: 14px;
    }

    #entry {
        border-radius: 14px;
        padding: 10px 14px;
        margin: 4px 0;
        background-color: rgba(49, 50, 68, 0.35);
        color: @text;
        transition: background 0.2s ease;
    }

    #entry:selected {
        background-color: rgba(203, 166, 247, 0.30);
        box-shadow: inset 0 0 0 1px rgba(203, 166, 247, 0.45);
    }

    #entry:selected #text {
        color: @text;
    }

    #entry:hover {
        background-color: rgba(137, 180, 250, 0.35);
    }

    #img {
        margin-right: 12px;
        border-radius: 10px;
    }

    #text {
        color: @text;
    }
  '';
}
