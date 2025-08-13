{...}: {
  programs.nixvim = {
    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };
    
    keymaps = [
      # Basic mappings
      {
        mode = "i";
        key = "jj";
        action = "<Esc><Esc><Esc>";
        options = {
          noremap = true;
          desc = "Exit insert mode";
        };
      }
      
      # Insert mode navigation
      {
        mode = "i";
        key = "<C-j>";
        action = "<Down>";
        options = {
          noremap = true;
          desc = "Move down in insert mode";
        };
      }
      {
        mode = "i";
        key = "<C-k>";
        action = "<Up>";
        options = {
          noremap = true;
          desc = "Move up in insert mode";
        };
      }
      {
        mode = "i";
        key = "<C-h>";
        action = "<Left>";
        options = {
          noremap = true;
          desc = "Move left in insert mode";
        };
      }
      {
        mode = "i";
        key = "<C-l>";
        action = "<Right>";
        options = {
          noremap = true;
          desc = "Move right in insert mode";
        };
      }
      {
        mode = "i";
        key = "<C-f>";
        action = "<Delete>";
        options = {
          noremap = true;
          desc = "Delete character forward";
        };
      }
      
      # Normal mode navigation
      {
        mode = "n";
        key = "j";
        action = "gj";
        options = {
          noremap = true;
          desc = "Move down by visual line";
        };
      }
      {
        mode = "n";
        key = "k";
        action = "gk";
        options = {
          noremap = true;
          desc = "Move up by visual line";
        };
      }
      {
        mode = "n";
        key = ":";
        action = ";";
        options = {
          noremap = true;
          desc = "Repeat last character search";
        };
      }
      {
        mode = "n";
        key = ";";
        action = ":";
        options = {
          noremap = true;
          desc = "Command line";
        };
      }
      
      # File operations
      {
        mode = "n";
        key = "<leader>w";
        action = "<cmd>w<cr>";
        options = {
          desc = "Save file";
        };
      }
      
      # Clear search highlights
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<cr>";
        options = {
          desc = "Clear search highlights";
        };
      }
      
      # Buffer navigation
      {
        mode = "n";
        key = "<S-h>";
        action = "<cmd>bprevious<cr>";
        options = {
          desc = "Previous buffer";
        };
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<cmd>bnext<cr>";
        options = {
          desc = "Next buffer";
        };
      }
      
      # Window navigation
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options = {
          desc = "Go to left window";
        };
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options = {
          desc = "Go to lower window";
        };
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options = {
          desc = "Go to upper window";
        };
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options = {
          desc = "Go to right window";
        };
      }
      
      # Visual mode indentation
      {
        mode = "v";
        key = "<";
        action = "<gv";
        options = {
          desc = "Unindent and keep selection";
        };
      }
      {
        mode = "v";
        key = ">";
        action = ">gv";
        options = {
          desc = "Indent and keep selection";
        };
      }
      
      # Leader key mappings (clear them first)
      {
        mode = "n";
        key = "<Leader>";
        action = "<Nop>";
        options = {};
      }
      {
        mode = "x";
        key = "<Leader>";
        action = "<Nop>";
        options = {};
      }
      
      # LSP prefix mapping
      {
        mode = "n";
        key = "<Plug>(lsp)";
        action = "<Nop>";
        options = {};
      }
      {
        mode = "x";
        key = "<Plug>(lsp)";
        action = "<Nop>";
        options = {};
      }
      {
        mode = "n";
        key = "m";
        action = "<Plug>(lsp)";
        options = {};
      }
      {
        mode = "x";
        key = "m";
        action = "<Plug>(lsp)";
        options = {};
      }
      
      # Find prefix mapping
      {
        mode = "n";
        key = "<Plug>(ff)";
        action = "<Nop>";
        options = {};
      }
      {
        mode = "x";
        key = "<Plug>(ff)";
        action = "<Nop>";
        options = {};
      }
      {
        mode = "n";
        key = "n";
        action = "<Plug>(ff)";
        options = {};
      }
      {
        mode = "x";
        key = "n";
        action = "<Plug>(ff)";
        options = {};
      }
    ];
  };
}