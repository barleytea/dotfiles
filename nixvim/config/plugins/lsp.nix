{...}: {
  plugins = {
    # LSP Configuration
    lsp = {
      enable = true;
      servers = {
        # Nix language server (unstable 前提で常時有効)
        nil_ls = {
          enable = true;
        };

        # Lua language server
        lua_ls = {
          enable = true;
          settings.Lua = {
            diagnostics = {
              globals = ["vim"];
            };
            workspace = {
              library = [
                "\${3rd}/luv/library"
                "\${3rd}/busted/library"
              ];
              checkThirdParty = false;
            };
            telemetry = {
              enable = false;
            };
          };
        };

        # Go language server
        gopls = {
          enable = true;
          settings = {
            gopls = {
              semanticTokens = true;
              usePlaceholders = true;
              staticcheck = true;
            };
          };
        };

        # Add more language servers as needed
      };

      # Key mappings for LSP
      keymaps = {
        silent = true;
        lspBuf = {
          "gd" = "definition";
          "gD" = "declaration";
          "gr" = "references";
          "gI" = "implementation";
          "gt" = "type_definition";
          "K" = "hover";
          "<leader>ca" = "code_action";
          "<C-k>" = "signature_help";
          "<leader>rn" = "rename";
        };
        diagnostic = {
          "[d" = "goto_next";
          "]d" = "goto_prev";
          "<leader>e" = "open_float";
          "<leader>q" = "setloclist";
        };
      };
    };

    # None-ls for formatting and diagnostics
    none-ls = {
      enable = true;
      sources = {
        formatting = {
          stylua.enable = true;
          nixpkgs_fmt.enable = true;
        };
      };
    };

    # LSP progress indicator
    fidget = {
      enable = true;
    };
  };
}
