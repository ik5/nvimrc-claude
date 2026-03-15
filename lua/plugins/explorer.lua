-- File explorer: neo-tree.nvim
-- Imports the LazyVim extra, adds nvim-window-picker, and applies custom config.

return {
  -- ── Window picker: lets you choose which split to open a file in ─────────
  {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    event = "VeryLazy",
    version = "2.*",
    opts = {
      hint = "floating-big-letter",
      filter_rules = {
        include_current_win = false,
        autoselect_one = true,
        bo = {
          -- never pick these as targets
          filetype = { "neo-tree", "neo-tree-popup", "notify", "snacks_notif" },
          buftype = { "terminal", "quickfix" },
        },
      },
    },
  },

  -- ── neo-tree configuration ────────────────────────────────────────────────
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = { "s1n7ax/nvim-window-picker" },

    -- Add F3 toggle on top of LazyVim's <leader>e / <leader>fe
    keys = {
      {
        "<F3>",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = LazyVim.root() })
        end,
        desc = "Toggle Explorer (Root Dir)",
      },
    },

    opts = {
      -- Start closed (open only on explicit toggle)
      close_if_last_window = true,

      -- Left sidebar
      window = {
        position = "left",
        width = 35,
        mappings = {
          -- Open file in the current window
          ["<CR>"] = "open",
          -- Pick a window with the letter overlay, then open into it directly
          ["w"] = "open_with_window_picker",
          -- Pick a window, then open in a horizontal split of that window
          ["<C-x>"] = {
            function(state)
              local node = state.tree:get_node()
              if node.type == "directory" then return end
              local picker = require("window-picker")
              local win = picker.pick_window()
              if win then
                vim.api.nvim_set_current_win(win)
                vim.cmd("split " .. vim.fn.fnameescape(node.path))
              end
            end,
            desc = "Open in horizontal split (pick window)",
          },
          -- Pick a window, then open in a vertical split of that window
          ["<C-v>"] = {
            function(state)
              local node = state.tree:get_node()
              if node.type == "directory" then return end
              local picker = require("window-picker")
              local win = picker.pick_window()
              if win then
                vim.api.nvim_set_current_win(win)
                vim.cmd("vsplit " .. vim.fn.fnameescape(node.path))
              end
            end,
            desc = "Open in vertical split (pick window)",
          },
        },
      },

      -- LSP diagnostics shown as icons next to files
      enable_diagnostics = true,
      default_component_configs = {
        diagnostics = {
          symbols = {
            hint  = " ",
            info  = " ",
            warn  = " ",
            error = " ",
          },
          highlights = {
            hint  = "DiagnosticSignHint",
            info  = "DiagnosticSignInfo",
            warn  = "DiagnosticSignWarn",
            error = "DiagnosticSignError",
          },
        },
        -- Icons via mini.icons (already installed by LazyVim)
        icon = {
          folder_closed = "",
          folder_open   = "",
          folder_empty  = "",
          default       = "",
          highlight     = "NeoTreeFileIcon",
        },
        git_status = {
          symbols = {
            -- LazyVim already sets unstaged/staged; extend with the rest:
            added     = "✚",
            modified  = "",
            deleted   = "✖",
            renamed   = "󰁕",
            untracked = "",
            ignored   = "",
            unstaged  = "󰄱",
            staged    = "󰱒",
            conflict  = "",
          },
        },
      },

      filesystem = {
        filtered_items = {
          hide_dotfiles   = false,  -- show dotfiles
          hide_gitignored = false,  -- show gitignored files (dimmed)
        },
      },
    },
  },
}
