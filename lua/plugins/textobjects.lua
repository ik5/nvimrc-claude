-- Additional text objects
--
-- mini.surround is loaded via the LazyVim extra (lazy.lua).
-- This file adds nvim-various-textobjs on top.
--
-- LazyVim already provides via mini.ai + nvim-treesitter-textobjects:
--   af/if  function        ac/ic  class          ao/io  code block (treesitter)
--   au/iu  function call   aa/ia  argument       ag/ig  entire buffer
--   aq/iq  any quote       ab/ib  any bracket    at/it  HTML tag
--
-- nvim-various-textobjs adds objects that mini.ai does NOT cover.
-- Conflicts with the above are disabled via `disabledDefaults`:
--   ao/io  anyBracket      → mini.ai handles brackets
--   aq/iq  anyQuote        → mini.ai handles quotes
--   ag/ig  greedyOuterIndentation → mini.ai uses g for buffer

return {
  {
    "chrisgrieser/nvim-various-textobjs",
    -- Must not be loaded lazily via buffer events — keymaps need to be
    -- registered before the first edit.  VeryLazy fires after UIEnter,
    -- which is safe.
    event = "VeryLazy",
    opts = {
      keymaps = {
        useDefaults = true,
        disabledDefaults = {
          -- Already covered by mini.ai:
          "ao", "io",   -- anyBracket    (mini.ai handles bracket pairs)
          "aq", "iq",   -- anyQuote      (mini.ai handles quotes)
          "ag", "ig",   -- greedyOuterIndentation (mini.ai uses g = buffer)
        },
      },
    },
  },
}

-- ── Quick reference: new objects from nvim-various-textobjs ───────────────
--
--   iS / aS   subword      — one segment of camelCase or snake_case
--   ii / ai   indentation  — lines at same indent level (great for Python)
--   iv / av   value        — right-hand side of an assignment / key-value pair
--   ik / ak   key          — left-hand side of an assignment / key-value pair
--   iz / az   closedFold
--   im / am   chainMember  — one element in a method chain  a.b.c
--   iF / aF   filepath
--   i# / a#   colour value — e.g. #ff0000
--   iD / aD   [[double square brackets]]
--   iN / aN   notebook cell
--
--   Single-key (visual / operator-pending, no inner/outer):
--   !         diagnostic under cursor
--   L         URL
--   gG        entire buffer (alternative to ag/ig from mini.ai)
--   gw        visible lines in window
--   g;        last change
