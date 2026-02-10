{
  programs.helix = {
    enable = true;
    settings = {
      keys = {
        normal = {
          "j" = "move_visual_line_down";
          "k" = "move_visual_line_up";
          ":" = "repeat_last_motion";
          ";" = "command_mode";
          "C-h" = "jump_view_left";
          "C-j" = "jump_view_down";
          "C-k" = "jump_view_up";
          "C-l" = "jump_view_right";
          "S-h" = "goto_previous_buffer";
          "S-l" = "goto_next_buffer";
          "space" = {
            "w" = ":write";
          };
        };
        insert = {
          "j" = { "j" = "normal_mode"; };
          "C-h" = "move_char_left";
          "C-j" = "move_line_down";
          "C-k" = "move_line_up";
          "C-l" = "move_char_right";
        };
      };
    };
  };
}
