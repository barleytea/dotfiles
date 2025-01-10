return {
  -- add dracula
  {
    "Mofiqul/dracula.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      transparent_bg = true,
      colors = {
        bg = "NONE",
      },
      overrides = {
        Normal = { bg = "NONE" },
        NormalFloat = { bg = "NONE" },
        SignColumn = { bg = "NONE" },
        TelescopeNormal = { bg = "NONE" },
        NvimTreeNormal = { bg = "NONE" },
      },
    },
  },

  -- Configure LazyVim to load dracula
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "dracula",
    },
  },
}
