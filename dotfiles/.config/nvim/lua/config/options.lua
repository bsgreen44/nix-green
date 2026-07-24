-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt
vim.g.autoformat = false

opt.relativenumber = true
opt.wrap = false
opt.conceallevel = 0 -- Don't hide quotes in JSON
