{...}: {
  # VSCode-specific configuration
  extraConfigLua = ''
    -- VSCode-specific settings
    if vim.g.vscode then
      -- Disable some plugins that don't work well in VSCode
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      -- Override some settings for VSCode
      vim.opt.hlsearch = false     -- Let VSCode handle highlighting
      vim.opt.cursorline = false   -- Let VSCode handle cursor line
      vim.opt.cursorcolumn = false -- Let VSCode handle cursor column

      -- VSCode-specific keymaps
      local vscode = require('vscode-neovim')

      -- Window navigation using VSCode commands
      vim.keymap.set('n', '<C-h>', function()
        vscode.call('workbench.action.navigateLeft')
      end, { silent = true, desc = "Navigate left in VSCode" })

      vim.keymap.set('n', '<C-j>', function()
        vscode.call('workbench.action.navigateDown')
      end, { silent = true, desc = "Navigate down in VSCode" })

      vim.keymap.set('n', '<C-k>', function()
        vscode.call('workbench.action.navigateUp')
      end, { silent = true, desc = "Navigate up in VSCode" })

      vim.keymap.set('n', '<C-l>', function()
        vscode.call('workbench.action.navigateRight')
      end, { silent = true, desc = "Navigate right in VSCode" })

      -- File operations
      vim.keymap.set('n', '<leader>w', function()
        vscode.call('workbench.action.files.save')
      end, { silent = true, desc = "Save file in VSCode" })

      vim.keymap.set('n', '<leader>q', function()
        vscode.call('workbench.action.closeActiveEditor')
      end, { silent = true, desc = "Close editor in VSCode" })

      vim.keymap.set('n', '<leader>e', function()
        vscode.call('workbench.view.explorer')
      end, { silent = true, desc = "Show explorer in VSCode" })

      vim.keymap.set('n', '<leader>f', function()
        vscode.call('workbench.action.quickOpen')
      end, { silent = true, desc = "Quick open in VSCode" })

      -- Search operations
      vim.keymap.set('n', '<leader>/', function()
        vscode.call('workbench.action.findInFiles')
      end, { silent = true, desc = "Find in files" })

      vim.keymap.set('n', '<leader>*', function()
        vscode.call('workbench.action.findInFiles', { query = vim.fn.expand('<cword>') })
      end, { silent = true, desc = "Find word under cursor" })

      -- LSP operations (delegate to VSCode)
      vim.keymap.set('n', 'gd', function()
        vscode.call('editor.action.revealDefinition')
      end, { silent = true, desc = "Go to definition" })

      vim.keymap.set('n', 'gr', function()
        vscode.call('editor.action.goToReferences')
      end, { silent = true, desc = "Go to references" })

      vim.keymap.set('n', 'gi', function()
        vscode.call('editor.action.goToImplementation')
      end, { silent = true, desc = "Go to implementation" })

      vim.keymap.set('n', 'K', function()
        vscode.call('editor.action.showHover')
      end, { silent = true, desc = "Show hover" })

      vim.keymap.set('n', '<leader>ca', function()
        vscode.call('editor.action.quickFix')
      end, { silent = true, desc = "Code actions" })

      vim.keymap.set('n', '<leader>rn', function()
        vscode.call('editor.action.rename')
      end, { silent = true, desc = "Rename symbol" })

      -- Format document
      vim.keymap.set('n', '<leader>fm', function()
        vscode.call('editor.action.formatDocument')
      end, { silent = true, desc = "Format document" })

      -- Git operations
      vim.keymap.set('n', '<leader>gg', function()
        vscode.call('workbench.view.scm')
      end, { silent = true, desc = "Show git panel" })

      vim.keymap.set('n', '<leader>gd', function()
        vscode.call('git.openChange')
      end, { silent = true, desc = "Show git diff" })

      -- Terminal
      vim.keymap.set('n', '<C-`>', function()
        vscode.call('workbench.action.terminal.toggleTerminal')
      end, { silent = true, desc = "Toggle terminal" })

      -- Command palette
      vim.keymap.set('n', '<leader>p', function()
        vscode.call('workbench.action.showCommands')
      end, { silent = true, desc = "Show command palette" })

      -- Zen mode
      vim.keymap.set('n', '<leader>z', function()
        vscode.call('workbench.action.toggleZenMode')
      end, { silent = true, desc = "Toggle zen mode" })

      -- Panel operations
      vim.keymap.set('n', '<leader>j', function()
        vscode.call('workbench.action.togglePanel')
      end, { silent = true, desc = "Toggle panel" })

      vim.keymap.set('n', '<leader>b', function()
        vscode.call('workbench.action.toggleSidebarVisibility')
      end, { silent = true, desc = "Toggle sidebar" })

      -- Debug
      vim.keymap.set('n', '<F5>', function()
        vscode.call('workbench.action.debug.start')
      end, { silent = true, desc = "Start debugging" })

      vim.keymap.set('n', '<F9>', function()
        vscode.call('editor.debug.action.toggleBreakpoint')
      end, { silent = true, desc = "Toggle breakpoint" })

      -- Notifications
      vim.keymap.set('n', '<leader>n', function()
        vscode.call('notifications.showList')
      end, { silent = true, desc = "Show notifications" })

      -- Multi-cursor (VSCode handles this natively)
      vim.keymap.set('n', '<C-d>', function()
        vscode.call('editor.action.addSelectionToNextFindMatch')
      end, { silent = true, desc = "Add selection to next find match" })

      vim.keymap.set('n', '<C-u>', function()
        vscode.call('cursorUndo')
      end, { silent = true, desc = "Cursor undo" })

      -- Extensions
      vim.keymap.set('n', '<leader>x', function()
        vscode.call('workbench.view.extensions')
      end, { silent = true, desc = "Show extensions" })

      -- Settings
      vim.keymap.set('n', '<leader>,', function()
        vscode.call('workbench.action.openSettings')
      end, { silent = true, desc = "Open settings" })
    end
  '';

  # Add VSCode-compatible keymaps to the main keymap list
  keymaps = [
    # These keymaps are conditionally applied in the extraConfigLua above
    # We keep the basic navigation keymaps here as fallbacks
  ];
}
