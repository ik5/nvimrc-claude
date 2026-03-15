-- Code highlight enhancements
--
--   hlargs.nvim          – highlight function arguments in declarations
--                          and every usage inside the body (treesitter)
--   rainbow-delimiters   – rainbow () [] {} up to N nesting levels
--                          (treesitter; only colors the actual delimiters,
--                          not the content between them)
--   eyeliner.nvim        – always-on highlights on the current line showing
--                          which characters are unique (1 keystroke with f/t)
--                          vs non-unique (2+ keystrokes). Complements flash.nvim
--                          which provides the actual jump labels on keypress.
--                          highlight_on_key = false avoids remapping f/t/F/T
--                          so flash.nvim handles those keys uninterrupted.

return {

  -- ── hlargs.nvim ───────────────────────────────────────────────────────
  {
    "m-demare/hlargs.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      -- Highlight parameter names in the function signature
      paint_arg_declarations = true,
      -- Highlight every use of those parameters inside the body
      paint_arg_usages = true,
      -- Also highlight variables bound in catch / except blocks
      paint_catch_blocks = {
        declarations = true,
        usages       = true,
      },
      -- Disable in filetypes where treesitter has no arg queries
      excluded_filetypes = { "help", "man", "TelescopePrompt" },
    },
  },

  -- ── eyeliner.nvim ─────────────────────────────────────────────────────
  {
    "jinh0/eyeliner.nvim",
    event = "VeryLazy",
    opts = {
      -- Always show highlights on cursor move (no key remapping → no conflict
      -- with flash.nvim which already intercepts f/t/F/T)
      highlight_on_key = false,
      -- Dim characters that are not unique on the current line so the
      -- highlighted unique ones stand out more
      dim = true,
    },
  },

  -- ── rainbow-delimiters ────────────────────────────────────────────────
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "VeryLazy",
    -- Works out of the box once loaded; colors cycle through 7 levels.
    -- To override the highlight list (colors) or per-language strategy,
    -- uncomment and edit:
    --
    -- config = function()
    --   require("rainbow-delimiters.setup").setup({
    --     highlight = {
    --       "RainbowDelimiterRed",
    --       "RainbowDelimiterYellow",
    --       "RainbowDelimiterBlue",
    --       "RainbowDelimiterOrange",
    --       "RainbowDelimiterGreen",
    --       "RainbowDelimiterViolet",
    --       "RainbowDelimiterCyan",
    --     },
    --   })
    -- end,
  },

}
