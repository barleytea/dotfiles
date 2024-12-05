{
  config,
  lib,
  pkgs,
  ...
}: let

in {
  programs.starship = {
    enable = true;
    settings = {
      format = ''
      [┌───────────────────](bold green)
      [│](bold green)$kubernetes$directory$nodejs$rust$java$golang$git_branch$git_state$git_status$time
      [└─>](bold green)'';
      scan_timeout = 10;
      add_newline = false;

      kubernetes = {
        format = "[$symbol$context](green) ";
        disabled = false;
      };

      directory = {
        truncation_length = 100;
        truncate_to_repo = false;
      };

      git_branch = {
        format = "[$symbol$branch(:$remote_branch)]($style)";
      };

      nodejs = {
        format = "[$symbol($version )]($style)";
      };

      rust = {
        format = "[$symbol($version )]($style)";
      };

      java = {
        format = "[$symbol($version )]($style)";
      };

      golang = {
        format = "[$symbol($version )]($style)";
      };
    };
  };
}
