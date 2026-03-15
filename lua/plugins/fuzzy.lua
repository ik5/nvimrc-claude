-- Fuzzy finder via snacks.picker (ships with snacks.nvim, already loaded).
-- The snacks_picker extra (imported in lazy.lua) registers snacks as the
-- active LazyVim picker and wires up the default keymaps.
--
-- Default keymaps provided by the extra (selection):
--   <leader>,        Buffers
--   <leader>/        Grep (root dir)
--   <leader>:        Command history
--   <leader><Space>  Find files (root dir)
--   <leader>n        Notification history
--   <leader>fb/ff/fr Files pickers
--   <leader>gs       Git status
--   <leader>gS       Git stash
--   <leader>sh       Help pages       ← documentation
--   <leader>sM       Man pages        ← documentation
--   <leader>sd/sD    Diagnostics
--   <leader>ss/sS    LSP symbols
--
-- This file:
--   1. Resolves key conflicts with our keymaps.lua
--   2. Adds git log / commits pickers

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        -- Unified split/window-pick keys matching neo-tree and keymaps.lua
        win = {
          input = {
            keys = {
              -- <C-x> = horizontal split (replaces <C-s>, consistent with neo-tree)
              ["<C-x>"] = { "edit_split", mode = { "n", "i" } },
              -- w = pick destination window (normal mode only; insert mode needs w for typing)
              ["w"] = { { "pick_win", "jump" }, mode = "n" },
            },
          },
          list = {
            keys = {
              ["<C-x>"] = "edit_split",
              ["w"]     = { "pick_win", "jump" },
            },
          },
        },
      },
    },
    keys = {

      -- ── Conflict: <leader>gd / <leader>gD ─────────────────────────────────
      -- snacks_picker maps <leader>gd → git diff and <leader>gD → git diff
      -- (origin).  Our keymaps.lua reserves <leader>gd for LSP split
      -- definition, so we drop the snacks bindings and add them under
      -- <leader>G* (capital G = git diff family).
      { "<leader>gd", false },   -- remove snacks git-diff (LSP binding wins)
      { "<leader>gD", false },   -- remove snacks git-diff origin

      { "<leader>Gd", function() Snacks.picker.git_diff() end,
        desc = "Git Diff (hunks)" },
      { "<leader>GD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end,
        desc = "Git Diff (origin)" },

      -- ── Git log / commits ─────────────────────────────────────────────────
      { "<leader>gL",  function() Snacks.picker.git_log() end,
        desc = "Git Log (all commits)" },
      { "<leader>gll", function() Snacks.picker.git_log_file() end,
        desc = "Git Log (current file)" },
      { "<leader>gb",  function() Snacks.picker.git_branches() end,
        desc = "Git Branches" },

    },
  },
}
