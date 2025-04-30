return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    main = 'nvim-treesitter.configs',
    opts = {
      highlight = { enable = true },
      ensure_installed = {}
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "CursorMoved",
  },
}
