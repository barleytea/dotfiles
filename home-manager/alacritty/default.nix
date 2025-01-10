{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "Hack Nerd Font";
          style = "Regular";
        };
        bold = {
          family = "Hack Nerd Font";
          style = "Bold";
        };
        italic = {
          family = "Hack Nerd Font";
          style = "Italic";
        };
        bold_italic = {
          family = "Hack Nerd Font";
          style = "Bold Italic";
        };
        size = 12.0;
      };
      window = {
        opacity = 0.75;
      };
      terminal = {
        shell = {
          program = "zsh";
          args = [
            "-l"
            "-c"
            "zellij attach --index 0 --create"
          ];
        };
      };
    };
  };
}
