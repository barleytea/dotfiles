{
  config,
  lib,
  pkgs,
  ...
}: let

in {
  programs.fish = {
    enable = true;

    plugins = [
      { name = "z"; src = pkgs.fishPlugins.z.src; }
      { name = "fish-bd"; src = pkgs.fishPlugins.fish-bd.src; }
      {
        name = "plugin-peco";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "plugin-peco";
          rev = "0a3282c9522c4e0102aaaa36f89645d17db78657";
          sha256 = "005r6yar254hkx6cpd2g590na812mq9z9a17ghjl6sbyyxq24jhi";
        };
      }
      {
        name = "fish-peco_select_ghq_repository";
        src = pkgs.fetchFromGitHub {
          owner = "yoshiori";
          repo = "fish-peco_select_ghq_repository";
          rev = "1b0e6333e7c7963f4eaacd0092fa0051b26c9a82";
          sha256 = "1fzmmnkk5n7zqsar9cvfm1i2f6mp4paclb8pn55f3y18xzgdbwyv";
        };
      }
      {
        name = "fish-peco_select_ghq_repository";
        src = pkgs.fetchFromGitHub {
          owner = "yoshiori";
          repo = "fish-peco_select_ghq_repository";
          rev = "1b0e6333e7c7963f4eaacd0092fa0051b26c9a82";
          sha256 = "1fzmmnkk5n7zqsar9cvfm1i2f6mp4paclb8pn55f3y18xzgdbwyv";
        };
      }
      {
        name = "tsu-nera/fish-peco_recentd";
        src = pkgs.fetchFromGitHub {
          owner = "tsu-nera";
          repo = "fish-peco_recentd";
          rev = "d157af22e319b9fe9f859bc6f2a96dd2b3ff7b89";
          sha256 = "18k4y5lflzlnnrmnif59l1jx5l8cg94mlvr38845blq858c9a12d";
        };
      }
      {
        name = "decors/fish-ghq";
        src = pkgs.fetchFromGitHub {
          owner = "decors";
          repo = "fish-ghq";
          rev = "cafaaabe63c124bf0714f89ec715cfe9ece87fa2";
          sha256 = "0cv7jpvdfdha4hrnjr887jv1pc6vcrxv2ahy7z6x562y7fd77gg9";
        };
      }
      {
        name = "lilyball/nix-env.fish";
        src = pkgs.fetchFromGitHub {
          owner = "lilyball";
          repo = "nix-env.fish";
          rev = "7b65bd228429e852c8fdfa07601159130a818cfa";
          sha256 = "069ybzdj29s320wzdyxqjhmpm9ir5815yx6n522adav0z2nz8vs4";
        };
      }
    ];

    interactiveShellInit = ''
      alias e='eza --icons --git'
      alias l=e
      alias ls=e
      alias ea='eza -a --icons --git'
      alias la=ea
      alias ee='eza -aahl --icons --git'
      alias ll=ee
      alias et='eza -T -L 3 -a -I "node_modules|.git|.cache" --icons'
      alias lt=et
      alias eta='eza -T -a -I "node_modules|.git|.cache" --color=always --icons | less -r'
      alias lta=eta
      alias l='clear && ls'
      alias vim=nvim
      alias g=git
      alias gmc='gitmoji -c'

      starship init fish | source

      # asdf
      if test -f $HOME/.nix-profile/share/asdf-vm/asdf.fish
        source $HOME/.nix-profile/share/asdf-vm/asdf.fish
      end

      # local.fish
      if test -f $HOME/.config/fish/local.fish
        echo "local.fish loaded."
        source $HOME/.config/fish/local.fish
      end
    '';

    functions = {
      ghq_key_bindings = ''
        fish_deafult_key_bindings
        bind \cg '__ghq_repository_search'
        if bind -M insert >/dev/null 2>/dev/null
          bind -M insert \cg '__ghq_repository_search'
        end
      '';
    };
  };
}
