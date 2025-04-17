{ pkgs, ... }: {
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
        option_as_alt = "Both";
      };
      scrolling = {
        history = 10000;
        multiplier = 3;
      };
      terminal = {
        shell = {
          program = "${pkgs.zsh}/bin/zsh";
          args = [
            "-l"
            "-c"
            "${pkgs.zellij}/bin/zellij attach --index 0 --create"
          ];
        };
      };
    };
  };
}
