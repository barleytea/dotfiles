return {
  -- フォーマッター
  {
    "stevearc/conform.nvim",
    lazy = true,
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format",
      },
    },
    opts = {
      -- LazyVimとの互換性を考慮した設定
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        javascript = { { "prettierd", "prettier" } },
        typescript = { { "prettierd", "prettier" } },
        json = { { "prettierd", "prettier" } },
        markdown = { { "prettierd", "prettier" } },
        css = { { "prettierd", "prettier" } },
        html = { { "prettierd", "prettier" } },
        go = { "gofmt" },
        rust = { "rustfmt" },
      },
      -- 自動フォーマット設定
      format_on_save = function(bufnr)
        -- ignore large files
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
        if ok and stats and stats.size > max_filesize then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
    },
  },

  -- リンター
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- LazyVimとの互換性を考慮した設定
      linters_by_ft = {
        lua = { "luacheck" },
        python = { "flake8", "mypy" },
        javascript = { "eslint" },
        typescript = { "eslint" },
        go = { "golangci_lint" },
      },
    },
    config = function(_, opts)
      local lint = require("lint")
      lint.linters_by_ft = opts.linters_by_ft

      -- 自動実行設定
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })

      -- キーマップ設定
      vim.keymap.set("n", "<leader>cl", function()
        lint.try_lint()
      end, { desc = "Lint" })
    end,
  },
}
