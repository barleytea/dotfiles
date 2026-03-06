{...}: {
  opts = {
    # Basic settings
    number = true;
    relativenumber = true;
    cursorline = true;
    cursorcolumn = true;
    wrap = false;

    # Tab and indentation
    tabstop = 2;
    softtabstop = 2;
    shiftwidth = 2;
    expandtab = true;
    smartindent = true;
    autoindent = true;
    shiftround = true;

    # Search settings
    hlsearch = true;
    incsearch = true;
    ignorecase = true;
    smartcase = true;

    # Editor behavior
    autoread = true;
    autowrite = true;
    confirm = true;
    mouse = "a";
    clipboard = "unnamedplus";

    # Visual settings
    termguicolors = true;
    background = "dark";
    signcolumn = "yes";
    showmode = false;
    showcmd = true;
    ruler = true;
    showmatch = true;
    laststatus = 3; # Global statusline

    # Splitting
    splitbelow = true;
    splitright = true;
    splitkeep = "screen";

    # Scrolling
    scrolloff = 8;
    sidescrolloff = 8;

    # Backup and undo
    backup = false;
    writebackup = false;
    swapfile = false;
    undofile = true;
    undolevels = 10000;

    # Timing
    updatetime = 250;
    timeoutlen = 300;
    ttimeoutlen = 50;

    # Completion
    completeopt = "menu,menuone,noselect";
    wildmode = "longest:full,full";
    wildmenu = true;

    # Formatting
    formatoptions = "jcroqlnt";

    # List characters
    list = true;
    listchars = {
      tab = "▸ ";
      trail = "·";
    };

    # Fill characters
    fillchars = {
      fold = " ";
      foldsep = " ";
      diff = "╱";
      eob = " ";
      foldopen = "▾";
      foldclose = "▸";
    };

    # Other
    conceallevel = 2;
    spelllang = ["en" "jp"];
    winminwidth = 5;
    sessionoptions = ["buffers" "curdir" "tabpages" "winsize" "help" "globals" "skiprtp" "folds"];

    # Transparency
    winblend = 20;
    pumblend = 20;

    # Grep
    grepformat = "%f:%l:%c:%m";
    grepprg = "rg --vimgrep";

    # Command line
    inccommand = "nosplit";
  };

  # Additional Lua configuration for complex settings
  extraConfigLua = ''
    -- Japanese input settings
    vim.opt.timeout = true
    vim.opt.timeoutlen = 1000
    vim.opt.ttimeoutlen = 50

    -- shortmess settings
    vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })

    -- Wildoptions
    vim.opt.wildoptions = 'pum'
    vim.opt.wildmode = 'longest:full'

    -- Neovim GUI settings
    if vim.g.neovide then
      vim.g.neovide_transparency = 0.8
      vim.g.transparency = 0.8
      vim.g.neovide_background_color = '#0f1117' .. string.format('%x', math.floor(255 * 0.8))
    end

    -- Transparency autocmds
    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = '*',
      callback = function()
        vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'NONE' })
        vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'NONE' })
        vim.api.nvim_set_hl(0, 'Pmenu', { bg = 'NONE' })
        vim.api.nvim_set_hl(0, 'PmenuSel', { bg = '#373844' })
      end,
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = function()
        vim.api.nvim_set_hl(0, "Normal", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "NonText", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE", ctermbg = "NONE" })
        vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE", ctermbg = "NONE" })
      end,
    })

    -- render-markdown highlight groups (transparency autocmdの後に配置)
    vim.api.nvim_create_autocmd('ColorScheme', {
      pattern = '*',
      callback = function()
        vim.api.nvim_set_hl(0, 'RenderMarkdownCode', { bg = '#282a36' })
        vim.api.nvim_set_hl(0, 'RenderMarkdownCodeBorder', { fg = '#6272a4', bg = '#282a36' })
        vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInline', { bg = '#343746' })
        vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInfo', { fg = '#bd93f9', bg = '#282a36' })
        vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { bg = '#3b2d4f' })
        vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { bg = '#2d3b4f' })
        vim.api.nvim_set_hl(0, 'RenderMarkdownH3Bg', { bg = '#2d4f3b' })
      end,
    })

    -- 初回ロード時のフォールバック
    vim.schedule(function()
      vim.api.nvim_set_hl(0, 'RenderMarkdownCode', { bg = '#282a36' })
      vim.api.nvim_set_hl(0, 'RenderMarkdownCodeBorder', { fg = '#6272a4', bg = '#282a36' })
      vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInline', { bg = '#343746' })
      vim.api.nvim_set_hl(0, 'RenderMarkdownCodeInfo', { fg = '#bd93f9', bg = '#282a36' })
      vim.api.nvim_set_hl(0, 'RenderMarkdownH1Bg', { bg = '#3b2d4f' })
      vim.api.nvim_set_hl(0, 'RenderMarkdownH2Bg', { bg = '#2d3b4f' })
      vim.api.nvim_set_hl(0, 'RenderMarkdownH3Bg', { bg = '#2d4f3b' })
    end)

    -- Markdown用 FileType autocmd
    local markdown_group = vim.api.nvim_create_augroup("MarkdownSettings", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
      group = markdown_group,
      pattern = { "markdown" },
      callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.linebreak = true
        vim.opt_local.breakindent = true
      end,
    })

    -- Highlighting
    vim.cmd('highlight SpecialKey ctermbg=235 guibg=#2c2d27')
    vim.cmd('highlight ColorColumn ctermbg=235 guibg=#2c2d27')
    vim.cmd('syntax on')
    vim.cmd('filetype plugin indent on')

    -- Terminal command
    if vim.fn.has('nvim') then
      vim.cmd('command! -nargs=* T split | wincmd j | resize 20 | terminal <args>')
      vim.cmd('autocmd TermOpen * startinsert')
    end

    -- Format Go files on save via LSP (gopls)
    local go_lsp_format = vim.api.nvim_create_augroup("GoLspFormat", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = go_lsp_format,
      pattern = "*.go",
      callback = function()
        vim.lsp.buf.format({ async = false })
      end,
    })
  '';
}
