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
		dependencies = { "s1n7ax/nvim-window-picker", "MunifTanjim/nui.nvim" },

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

			clipboard = {
				-- or "global"/"universal" to share a clipboard for each/all Neovim instance(s), respectively
				sync = "global",
			},

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
							if node.type == "directory" then
								return
							end
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
							if node.type == "directory" then
								return
							end
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

			enable_git_status = true,

			-- LSP diagnostics shown as icons next to files
			enable_diagnostics = true,
			default_component_configs = {
				diagnostics = {
					highlights = {
						hint = "DiagnosticSignHint",
						info = "DiagnosticSignInfo",
						warn = "DiagnosticSignWarn",
						error = "DiagnosticSignError",
					},
				},
				-- Icons via mini.icons (already installed by LazyVim)
				icon = {
					highlight = "NeoTreeFileIcon",
				},
				git_status = {
					symbols = {
						-- LazyVim already sets unstaged/staged; extend with the rest:
						added = "✚",
						modified = "",
						deleted = "✖",
						renamed = "󰁕",
						untracked = "",
						ignored = "",
						unstaged = "󰄱",
						staged = "󰱒",
						conflict = "",
					},
				},

				use_filtered_colors = true, -- Whether to use a different highlight
				name = {
					trailing_slash = true,
					use_filtered_colors = true, -- Whether to use a different highlight when the file is filtered (hidden, dotfile, etc.).
					use_git_status_colors = true,
					highlight = "NeoTreeFileName",
				},
				modified = {
					symbol = "[+]",
					highlight = "NeoTreeModified",
				},
			},

			filesystem = {
				filtered_items = {
					hide_dotfiles = false, -- show dotfiles
					hide_gitignored = false, -- show gitignored files (dimmed)
				},
				container = {
					enable_character_fade = true,
				},
				indent = {
					indent_size = 2,
					padding = 1, -- extra padding on left hand side
					-- indent guides
					with_markers = true,
					indent_marker = "│",
					last_indent_marker = "└",
					highlight = "NeoTreeIndentMarker",
					-- expander config, needed for nesting files
					with_expanders = nil, -- if nil and file nesting is enabled, will enable expanders
					expander_collapsed = "",
					expander_expanded = "",
					expander_highlight = "NeoTreeExpander",
				},
				follow_current_file = {
					enabled = true,
				},
				use_libuv_file_watcher = true,

				-- This is the key setting:
				cwd_target = {
					sidebar = "window", -- or "tab" / "global"
					current = "window",
				},
			},

			open_files_do_not_replace_types = { "terminal", "trouble", "qf" }, -- when opening files, do not use windows containing these filetypes or buftypes
			open_files_using_relative_paths = false,
			sort_case_insensitive = false,
		},
	},
}
