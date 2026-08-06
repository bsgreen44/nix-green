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
