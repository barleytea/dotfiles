--
print("Import base")
require("base")

-- Install lazy.nvim
print("Install lazy.nvim")
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set up lazy.nvim
print("Set up lazy.nvim")
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require('lazy').setup("plugins", {
  defaults = {
    lazy = true,
  },
  dev = {
    path = "@lazyPath@",
    patterns = { "." },
    fallback = true,
  },
  performance = {
    cache = {
      enable = true,
    },
    reset_packpath = true,
  }
})

print("init.lua finished")
