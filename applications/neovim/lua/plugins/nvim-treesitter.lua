return {
  {
    "nvim-treesitter/nvim-treesitter", 
    build = ":TSUpdate", 
    main = 'nvim-treesitter.configs', 
    opts = function(_, opts)
      opts.highlight = { enable = true }
      opts.ensure_installed = {}
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "CursorMoved",
  },
}