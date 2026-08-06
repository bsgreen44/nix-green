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
