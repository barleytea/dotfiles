{ pkgs, ... }:
{
  # https://github.com/nvim-treesitter/nvim-treesitter#i-get-query-error-invalid-node-type-at-position
  xdg.configFile."nvim/parser".source =
    let
      parsers = pkgs.symlinkJoin {
        name = "treesitter-parsers";
        paths =
          (pkgs.vimPlugins.nvim-treesitter.withPlugins (
            plugins: with plugins; [
              bash
              c
              css
              csv
              dart
              diff
              editorconfig
              fish
              git_config
              git_rebase
              gitcommit
              gitignore
              go
              gomod
              gosum
              helm
              html
              java
              javascript
              jq
              jsdoc
              json
              just
              lua
              make
              markdown
              nix
              proto
              regex
              rust
              sql
              tmux
              toml
              tsv
              tsx
              typescript
              vim
              yaml
            ]
          )).dependencies;
      };
    in
    "${parsers}/parser";
}