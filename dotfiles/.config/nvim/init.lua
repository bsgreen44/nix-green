vim.g.loaded_node_provider=0;vim.g.loaded_perl_provider=0;vim.g.ruby_host_prog='/nix/store/66vh4ikm9rvyi15fqiji892kpz5pmx13-neovim-ruby-env/bin/neovim-ruby-host';vim.g.python3_host_prog='/nix/store/c6xjrwfx6a2wz05by8ghx0y52b064f17-nvim-host-python3-3.14.6-env/bin/nvim-python3'
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader keys before loading lazy
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Load lazy.nvim with LazyVim
require("lazy").setup({
  spec = {
    -- LazyVim starter config
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    
    -- Catppuccin theme
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      opts = {
        flavour = "mocha", -- latte, frappe, macchiato, mocha
        transparent_background = true,
        integrations = {
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          treesitter = true,
          notify = true,
          mini = {
            enabled = true,
          },
        },
      },
    },
    
    -- Import additional LazyVim plugins
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.ui.mini-animate" },
    
    -- Import your custom plugins
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = true },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",  
      },
    },
  },
})

-- Set colorscheme
vim.cmd.colorscheme("catppuccin")
