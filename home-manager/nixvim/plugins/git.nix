{...}: {
  programs.nixvim = {
    plugins = {
      # Git signs in the gutter
      gitsigns = {
        enable = true;
        settings = {
          signs = {
            add = {
              text = "│";
            };
            change = {
              text = "│";
            };
            delete = {
              text = "_";
            };
            topdelete = {
              text = "‾";
            };
            changedelete = {
              text = "~";
            };
            untracked = {
              text = "┆";
            };
          };
          signcolumn = true;
          numhl = false;
          linehl = false;
          word_diff = false;
          watch_gitdir = {
            follow_files = true;
          };
          attach_to_untracked = true;
          current_line_blame = false;
          current_line_blame_opts = {
            virt_text = true;
            virt_text_pos = "eol";
            delay = 1000;
            ignore_whitespace = false;
          };
          current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>";
          sign_priority = 6;
          update_debounce = 100;
          status_formatter = null;
          max_file_length = 40000;
          preview_config = {
            border = "single";
            style = "minimal";
            relative = "cursor";
            row = 0;
            col = 1;
          };
        };
        
        # Key mappings for git operations
        # These will be set up through nixvim's keymap system
      };
      
      # Git integration with Neogit (alternative to lazygit)
      neogit = {
        enable = true;
        settings = {
          disable_signs = false;
          disable_hint = false;
          disable_context_highlighting = false;
          disable_commit_confirmation = false;
          disable_builtin_notifications = false;
          auto_refresh = true;
          disable_insert_on_commit = "auto";
          use_magit_keybindings = false;
          commit_popup = {
            kind = "split";
          };
          preview_buffer = {
            kind = "split";
          };
          popup = {
            kind = "split";
          };
          signs = {
            section = [ ">" "v" ];
            item = [ ">" "v" ];
            hunk = [ "" "" ];
          };
          integrations = {
            diffview = true;
          };
        };
      };
      
      # Git diff view - simplified configuration for nixvim compatibility
      diffview = {
        enable = true;
      };
    };
    
    # Git-related keymaps
    keymaps = [
      {
        mode = "n";
        key = "<leader>gg";
        action = "<cmd>Neogit<cr>";
        options = {
          desc = "Neogit";
        };
      }
      {
        mode = "n";
        key = "<leader>gd";
        action = "<cmd>DiffviewOpen<cr>";
        options = {
          desc = "Diffview Open";
        };
      }
      {
        mode = "n";
        key = "<leader>gh";
        action = "<cmd>DiffviewFileHistory<cr>";
        options = {
          desc = "Diffview File History";
        };
      }
      {
        mode = "n";
        key = "<leader>gc";
        action = "<cmd>DiffviewClose<cr>";
        options = {
          desc = "Diffview Close";
        };
      }
      {
        mode = "n";
        key = "]c";
        action = ''
          function()
            if vim.wo.diff then
              return ']c'
            end
            vim.schedule(function()
              require('gitsigns').next_hunk()
            end)
            return '<Ignore>'
          end
        '';
        options = {
          expr = true;
          desc = "Next git hunk";
        };
      }
      {
        mode = "n";
        key = "[c";
        action = ''
          function()
            if vim.wo.diff then
              return '[c'
            end
            vim.schedule(function()
              require('gitsigns').prev_hunk()
            end)
            return '<Ignore>'
          end
        '';
        options = {
          expr = true;
          desc = "Previous git hunk";
        };
      }
      {
        mode = ["n" "v"];
        key = "<leader>ghs";
        action = ":Gitsigns stage_hunk<CR>";
        options = {
          desc = "Stage hunk";
        };
      }
      {
        mode = ["n" "v"];
        key = "<leader>ghr";
        action = ":Gitsigns reset_hunk<CR>";
        options = {
          desc = "Reset hunk";
        };
      }
      {
        mode = "n";
        key = "<leader>ghS";
        action = "<cmd>Gitsigns stage_buffer<CR>";
        options = {
          desc = "Stage buffer";
        };
      }
      {
        mode = "n";
        key = "<leader>ghu";
        action = "<cmd>Gitsigns undo_stage_hunk<CR>";
        options = {
          desc = "Undo stage hunk";
        };
      }
      {
        mode = "n";
        key = "<leader>ghR";
        action = "<cmd>Gitsigns reset_buffer<CR>";
        options = {
          desc = "Reset buffer";
        };
      }
      {
        mode = "n";
        key = "<leader>ghp";
        action = "<cmd>Gitsigns preview_hunk<CR>";
        options = {
          desc = "Preview hunk";
        };
      }
      {
        mode = "n";
        key = "<leader>ghb";
        action = ''
          function()
            require('gitsigns').blame_line{full=true}
          end
        '';
        options = {
          desc = "Blame line";
        };
      }
      {
        mode = "n";
        key = "<leader>gtb";
        action = "<cmd>Gitsigns toggle_current_line_blame<CR>";
        options = {
          desc = "Toggle line blame";
        };
      }
      {
        mode = "n";
        key = "<leader>ghd";
        action = "<cmd>Gitsigns diffthis<CR>";
        options = {
          desc = "Diff this";
        };
      }
      {
        mode = "n";
        key = "<leader>ghD";
        action = ''
          function()
            require('gitsigns').diffthis('~')
          end
        '';
        options = {
          desc = "Diff this ~";
        };
      }
      {
        mode = "n";
        key = "<leader>gtd";
        action = "<cmd>Gitsigns toggle_deleted<CR>";
        options = {
          desc = "Toggle deleted";
        };
      }
    ];
  };
}