-- Extend blink.cmp with additional completion sources.
--
-- LazyVim already configures:
--   default sources : lsp, path, snippets, buffer
--   cmdline         : enabled, shows on ':'
--   treesitter draw : LSP items are highlighted with treesitter syntax
--
-- We add:
--   omni   – vim's omnifunc (disabled when LSP omni is active, no duplicates)
--   spell  – dictionary / spell-checker words (ribru17/blink-cmp-spell)
--   tmux   – words from visible tmux panes  (mgalliou/blink-cmp-tmux)

return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "ribru17/blink-cmp-spell",
      "mgalliou/blink-cmp-tmux",
    },
    opts = function(_, opts)
      -- Append extra sources to whatever LazyVim already sets
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or { "lsp", "path", "snippets", "buffer" }
      vim.list_extend(opts.sources.default, { "omni", "spell", "tmux" })

      opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {

        -- ── omni ────────────────────────────────────────────────────────────
        -- Wraps vim's omnifunc. Disabled when LSP provides its own omnifunc
        -- so there's no duplication with the lsp source.
        omni = {
          name = "Omni",
          module = "blink.cmp.sources.complete_func",
          enabled = function()
            return vim.bo.omnifunc ~= ""
              and vim.bo.omnifunc ~= "v:lua.vim.lsp.omnifunc"
          end,
          score_offset = -2,
        },

        -- ── spell ────────────────────────────────────────────────────────────
        -- Suggests words from vim's spell dictionary.
        -- Score is kept low so LSP/snippets appear first.
        spell = {
          name = "Spell",
          module = "blink-cmp-spell",
          score_offset = -5,
          -- Only show spell suggestions when spell is actually on
          enabled = function() return vim.wo.spell end,
        },

        -- ── tmux ─────────────────────────────────────────────────────────────
        -- Words from all visible tmux panes (great for CLI args, paths, etc.)
        -- Only active when nvim is running inside a tmux session.
        tmux = {
          name = "tmux",
          module = "blink-cmp-tmux",
          score_offset = -6,
          enabled = function() return vim.env.TMUX ~= nil end,
          opts = {
            all_panes = true,       -- include panes beyond the current one
            capture_history = true, -- also scan scrollback
          },
          async = true, -- don't block completion while tmux responds
        },
      })

      return opts
    end,
  },

  -- ── vim-dadbod-completion crash fix ───────────────────────────────────────
  -- The plugin's after/plugin file checks for the ancient completion.nvim API
  -- (`completion.addCompletionSource`) without verifying the method exists.
  -- Something in the loaded rtp provides a `completion` module that lacks this
  -- method, causing a crash on CmdlineEnter.
  -- Fix: inject a safe stub before the plugin loads so the call becomes a no-op.
  {
    "kristijanhusak/vim-dadbod-completion",
    init = function()
      if not package.loaded["completion"] then
        package.loaded["completion"] = {
          addCompletionSource = function() end, -- no-op stub
        }
      end
    end,
  },
}
