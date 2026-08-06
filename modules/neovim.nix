{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;  # Sets nvim as the system default editor
    viAlias = true;
    vimAlias = true;
    withRuby = true;
    withPython3 = true;
  };

  home.packages = with pkgs; [

    # LSP servers
    lua-language-server
    nil # Nix LSP
    pyright
    typescript-language-server
    vscode-langservers-extracted # HTML/CSS/JSON/ESLint
    yaml-language-server
    marksman # Markdown

    # Formatters
    stylua
    nixpkgs-fmt
    prettierd
    black

    # Linters
    eslint_d

    # Tools LazyVim expects
    ripgrep
    fd
    tree-sitter

    # Build tools for compiling nvim-treesitter parsers
    gcc
    gnumake

    # Image support for snacks.nvim
    imagemagick
    chafa # Terminal image viewer
    ghostscript # gs command for PostScript/PDF processing
    tectonic # Modern LaTeX engine
  ];

  # LazyVim configuration
  xdg.configFile."nvim/init.lua".text = ''
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
  '';

  # Create plugins directory for custom plugins
  home.file.".config/nvim/lua/plugins/user.lua".text = ''
    -- Disable Mason since we're using Nix for package management
    return {
      -- Disable mason.nvim
      { "mason-org/mason.nvim", enabled = false },
      { "mason-org/mason-lspconfig.nvim", enabled = false },
      { "jay-babu/mason-nvim-dap.nvim", enabled = false },

      -- Configure LSP servers to use Nix-installed binaries
      {
        "neovim/nvim-lspconfig",
        opts = {
          servers = {
            lua_ls = {},
            nil_ls = {},
            pyright = {},
            ts_ls = {},
            -- jsonls is configured by the lazyvim lang.json extra
            yamlls = {},
            marksman = {},
            -- Add more LSP servers as needed
          },
        },
      },
    }
  '';

  # LazyVim config customization
  home.file.".config/nvim/lua/config/options.lua".text = ''
    -- Options are automatically loaded before lazy.nvim startup
    -- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

    local opt = vim.opt
    vim.g.autoformat = false

    opt.relativenumber = true
    opt.wrap = false
    opt.conceallevel = 0 -- Don't hide quotes in JSON
  '';

  home.file.".config/nvim/lua/config/autocmds.lua".text = ''
    -- Autocmds are automatically loaded on the VeryLazy event
    -- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

    -- Make the background transparent so the terminal shows through.
    -- Runs on every colorscheme load so plugins can't re-apply an opaque bg.
    local transparent_groups = {
      "Normal",
      "NormalNC",
      "NormalFloat",
      "FloatBorder",
      "FloatTitle",
      "SignColumn",
      "LineNr",
      "CursorLineNr",
      "EndOfBuffer",
      "VertSplit",
      "WinSeparator",
      "StatusLine",
      "StatusLineNC",
      "TabLine",
      "TabLineFill",
      "Folded",
      "WhichKeyFloat",
      "SnacksNormal",
      "SnacksNormalNC",
      "SnacksDashboardNormal",
    }

    local function make_transparent()
      for _, group in ipairs(transparent_groups) do
        -- Resolve links so we edit real attributes, and keep the fg colors.
        local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
        hl.bg = nil
        hl.ctermbg = nil
        vim.api.nvim_set_hl(0, group, hl)
      end
    end

    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = make_transparent,
    })

    -- The colorscheme is already set by the time this file loads (VeryLazy),
    -- so apply once up front too.
    make_transparent()
  '';
}
