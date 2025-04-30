return {
  "lukas-reineke/indent-blankline.nvim",
  event = { "BufReadPost", "BufNewFile" },
  main = "ibl",
  priority = 1000,
  opts = {
    indent = {
      char = "│",
      tab_char = "│",
    },
    scope = { enabled = false },
    exclude = {
      filetypes = {
        "help",
        "alpha",
        "dashboard",
        "neo-tree",
        "Trouble",
        "lazy",
        "mason",
        "notify",
        "toggleterm",
        "lazyterm",
      },
    },
  },
  config = function(_, opts)
    vim.api.nvim_set_hl(0, "IblScope", { link = "Visual" })

    local highlight_group = vim.api.nvim_create_augroup("IndentBlanklineHighlight", { clear = true })
    vim.api.nvim_create_autocmd("ColorScheme", {
      callback = function()
        vim.schedule(function()
          vim.api.nvim_set_hl(0, "IblScope", { link = "Visual" })
        end)
      end,
      group = highlight_group,
    })

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        vim.schedule(function()
          vim.api.nvim_set_hl(0, "IblScope", { link = "Visual" })
        end)
      end,
      group = highlight_group,
    })

    vim.defer_fn(function()
      vim.api.nvim_set_hl(0, "IblScope", { link = "Visual" })
      require("ibl").setup(opts)
    end, 100)
  end,
}
