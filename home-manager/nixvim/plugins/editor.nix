{...}: {
  programs.nixvim = {
    plugins = {
      # Treesitter for syntax highlighting
      treesitter = {
        enable = true;
        nixvimInjections = true;
        
        settings = {
          highlight = {
            enable = true;
            additional_vim_regex_highlighting = false;
          };
          indent = {
            enable = true;
          };
          incremental_selection = {
            enable = true;
            keymaps = {
              init_selection = "<C-space>";
              node_incremental = "<C-space>";
              scope_incremental = false;
              node_decremental = "<bs>";
            };
          };
        };
        
        folding = false;
        nixGrammars = true;
      };
      
      # Treesitter text objects
      treesitter-textobjects = {
        enable = true;
        select = {
          enable = true;
          lookahead = true;
          keymaps = {
            "aa" = "@parameter.outer";
            "ia" = "@parameter.inner";
            "af" = "@function.outer";
            "if" = "@function.inner";
            "ac" = "@class.outer";
            "ic" = "@class.inner";
            "ii" = "@conditional.inner";
            "ai" = "@conditional.outer";
            "il" = "@loop.inner";
            "al" = "@loop.outer";
            "at" = "@comment.outer";
          };
        };
        move = {
          enable = true;
          gotoNextStart = {
            "]m" = "@function.outer";
            "]]" = "@class.outer";
          };
          gotoNextEnd = {
            "]M" = "@function.outer";
            "][" = "@class.outer";
          };
          gotoPreviousStart = {
            "[m" = "@function.outer";
            "[[" = "@class.outer";
          };
          gotoPreviousEnd = {
            "[M" = "@function.outer";
            "[]" = "@class.outer";
          };
        };
        swap = {
          enable = true;
          swapNext = {
            "<leader>a" = "@parameter.inner";
          };
          swapPrevious = {
            "<leader>A" = "@parameter.inner";
          };
        };
      };
      
      # Surround text objects
      nvim-surround = {
        enable = true;
      };
      
      # Comment plugin
      comment = {
        enable = true;
        settings = {
          opleader = {
            line = "gc";
            block = "gb";
          };
          toggler = {
            line = "gcc";
            block = "gbc";
          };
          extra = {
            above = "gcO";
            below = "gco";
            eol = "gcA";
          };
        };
      };
      
      # Which-key for keybinding hints
      which-key = {
        enable = true;
      };
      
      # Auto pairs
      nvim-autopairs = {
        enable = true;
      };
      
      # LazyGit integration
      lazygit = {
        enable = true;
      };
      
      # Terminal integration
      toggleterm = {
        enable = true;
      };
      
      # Sessions
      auto-session = {
        enable = true;
      };
      
      # Multiple cursors (handled by extraPlugins since not directly supported)
      # vim-multiple-cursors will be added via extraPlugins if needed
      
      # Flash for enhanced navigation
      flash = {
        enable = true;
      };
    };
  };
}