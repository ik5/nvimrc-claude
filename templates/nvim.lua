-- Per-project Neovim overrides
-- Copy this file to your project root as  .nvim.lua
-- First time: run  :trust  inside Neovim to approve it (stored in ~/.local/state/nvim/trust)
-- Subsequent opens: loaded automatically, no prompt.
--
-- Only the settings you uncomment here override the global defaults.
-- Everything else falls through to ~/.config/nvim.

local opt = vim.opt
local map = vim.keymap.set

-- ── Indentation ───────────────────────────────────────────────────────────────
-- opt.tabstop     = 2
-- opt.shiftwidth  = 2
-- opt.softtabstop = 2
-- opt.expandtab   = true   -- true = spaces, false = hard tabs

-- ── Line width ────────────────────────────────────────────────────────────────
-- opt.textwidth   = 80
-- opt.colorcolumn = "80"

-- ── Formatter overrides (conform.nvim) ────────────────────────────────────────
-- vim.g.conform_formatters = {
--   python = { "black" },            -- use black instead of ruff in this project
--   typescript = { "biome" },        -- use biome instead of prettier
-- }
--
-- Or use the conform API directly:
-- require("conform").formatters_by_ft.python = { "black" }

-- ── LSP overrides (also see .neoconf.json for JSON-based LSP settings) ────────
-- vim.lsp.buf_attach_client() -- advanced: attach a specific LSP client

-- ── Environment-specific keymaps ──────────────────────────────────────────────
-- map("n", "<leader>rr", "<cmd>!./run.sh<cr>", { desc = "Run project script" })

-- ── Spell ─────────────────────────────────────────────────────────────────────
-- opt.spell = false   -- disable spell checking for this project
