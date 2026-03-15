-- Remap LazyVim defaults that conflict with personal keybindings.
-- Strategy: disable the LazyVim key at the plugin-spec level, then add the
-- replacement. This fires at the right time rather than fighting load order.

return {
  -- ── \cf → \lf (code format) ──────────────────────────────────────────────
  -- LazyVim binds \cf to format (via conform.nvim).
  -- Our \cf = paste from ~/.vbuf, so format moves to \lf.
  {
    "stevearc/conform.nvim",
    optional = true,
    keys = {
      { "<leader>cf", false }, -- disable LazyVim's default
      {
        "<leader>lf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format Document/Range",
      },
    },
  },

  -- ── \cf fallback: also remove if bound via LSP (no conform) ──────────────
  {
    "neovim/nvim-lspconfig",
    optional = true,
    keys = {
      { "<leader>cf", false },
      {
        "<leader>lf",
        function() vim.lsp.buf.format({ async = true }) end,
        desc = "Format Document (LSP)",
      },
    },
  },
}
