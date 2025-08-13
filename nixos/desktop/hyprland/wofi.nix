# Wofi configuration
{ config, pkgs, ... }:

{
  # Create wofi configuration files
  environment.etc."xdg/wofi/config".text = ''
    width=600
    height=400
    location=center
    show=drun
    prompt=Applications
    filter_rate=100
    allow_markup=true
    no_actions=true
    halign=fill
    orientation=vertical
    content_halign=fill
    insensitive=true
    allow_images=true
    image_size=32
    gtk_dark=true
  '';

  environment.etc."xdg/wofi/style.css".text = ''
    window {
        margin: 0px;
        border: 1px solid #1e1e2e;
        background-color: #1e1e2e;
        border-radius: 15px;
    }

    #input {
        margin: 5px;
        border: none;
        color: #cdd6f4;
        background-color: #313244;
        border-radius: 15px;
    }

    #inner-box {
        margin: 5px;
        border: none;
        background-color: #1e1e2e;
        border-radius: 15px;
    }

    #outer-box {
        margin: 5px;
        border: none;
        background-color: #1e1e2e;
        border-radius: 15px;
    }

    #scroll {
        margin: 0px;
        border: none;
        border-radius: 15px;
    }

    #text {
        margin: 5px;
        border: none;
        color: #cdd6f4;
    }

    #entry {
        margin: 0px;
        border: none;
        border-radius: 15px;
        color: #cdd6f4;
        background-color: transparent;
    }

    #entry:selected {
        background-color: #585b70;
        border-radius: 15px;
    }

    #entry:selected #text {
        color: #cdd6f4;
    }

    #entry:hover {
        background-color: #45475a;
        border-radius: 15px;
    }
  '';
}