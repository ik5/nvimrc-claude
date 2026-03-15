-- Git management tools
--
-- LazyVim base already provides:
--   gitsigns.nvim   → <leader>gh*  hunk stage/reset/blame/diff (inline)
--   snacks pickers  → <leader>gs/gS/gb/gL/gll/Gd/GD  status/stash/branches/log/diff
--
-- This file adds:
--   neogit          → Magit-like panel: stage, commit, push, pull, fetch,
--                     branches, tags, remotes, log, rebase, stash
--   diffview.nvim   → Full-screen diff view and file history with code context
--
-- New keymaps:
--   <leader>gn   Neogit status (main entry point — covers everything)
--   <leader>gv   DiffviewOpen  (all current changes as side-by-side diff)
--   <leader>gV   DiffviewFileHistory %  (current file history + code)
--   <leader>gH   DiffviewFileHistory   (whole repo history)
--   <leader>gX   DiffviewClose

return {
  -- ── diffview.nvim ──────────────────────────────────────────────────────────
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewFocusFiles" },
    opts = {
      enhanced_diff_hl = true, -- extra highlights for changed words inside lines
      view = {
        -- side-by-side for normal diffs
        default = { layout = "diff2_horizontal" },
        -- unified layout for merge conflicts (easier to resolve)
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
      },
    },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>",                desc = "Diffview (all changes)" },
      { "<leader>gV", "<cmd>DiffviewFileHistory %<cr>",       desc = "Diffview file history" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>",         desc = "Diffview repo history" },
      { "<leader>gX", "<cmd>DiffviewClose<cr>",               desc = "Diffview close" },
    },
  },

  -- ── neogit ─────────────────────────────────────────────────────────────────
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",  -- used for rich diffs inside neogit
    },
    cmd = "Neogit",
    opts = {
      -- Use diffview for the diff panel (richer experience)
      integrations = { diffview = true, snacks = true },
      -- Unicode graph looks nicer with a Nerd Font
      graph_style = "unicode",
      log_view        = { kind = "split" },
      commit_editor   = { kind = "split", show_staged_diff = true },
      reflog_view     = { kind = "split" },
      merge_editor    = { kind = "split" },
      tag_editor      = { kind = "split" },
      -- Main status window in a floating panel
      kind = "floating",
    },
    keys = {
      { "<leader>gn", "<cmd>Neogit<cr>",              desc = "Neogit (status)" },
      { "<leader>gN", "<cmd>Neogit commit<cr>",       desc = "Neogit commit" },
    },
  },
}
