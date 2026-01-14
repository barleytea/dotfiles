{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.starship = {
    enable = true;
    enableZshIntegration = false;
    package = pkgs.starship;
    settings = {
      format = ''
      [┌───────────────────](bold green)
      [│](bold green)$kubernetes$aws$hostname$directory$nodejs$rust$java$golang$git_branch$git_state$git_status$time
      [└─>](bold green)'';
      scan_timeout = 10;
      add_newline = false;

      kubernetes = {
        format = "[$symbol$context](green) ";
        disabled = false;
      };

      aws = {
        format = "[$symbol$profile](green) ";
        disabled = false;
      };

      hostname = {
        format = "[$hostname]($style) ";
        ssh_only = true;
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

  home.sessionVariables = {
    STARSHIP_SHELL = "zsh";
  };
}
