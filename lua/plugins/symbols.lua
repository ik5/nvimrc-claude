-- Symbol outline panel via aerial.nvim
-- Imports the LazyVim extra (LSP + treesitter + dedup + lualine breadcrumb)
-- and overrides: right side, F4 toggle, closed by default.

return {
	{
		"stevearc/aerial.nvim",
		keys = {
			-- F4 toggle (in addition to LazyVim's <leader>cs)
			{ "<F4>", "<cmd>AerialToggle<cr>", desc = "Toggle Symbols (Aerial)" },
		},
		opts = {
			-- Open on the right side
			layout = {
				default_direction = "right",
				resize_to_content = false,
				width = 45,
				min_width = 35,
				-- These control the width of the aerial window.
				-- They can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
				-- min_width and max_width can be a list of mixed types.
				-- max_width = {40, 0.2} means "the lesser of 40 columns or 20% of total"
				max_width = { 85, 0.5 },

				win_opts = {
					winhl = "Normal:NormalFloat,FloatBorder:NormalFloat,SignColumn:SignColumnSB",
					signcolumn = "yes",
					statuscolumn = " ",
				},
			},

			filter_kind = false,

			-- Keep the panel closed until explicitly toggled
			open_automatic = false,

			-- Highlight the symbol the cursor is currently inside
			highlight_on_hover = true,

			-- Cursor in the editor jumps to match the aerial selection
			autojump = false,

			-- Auto-scroll aerial to follow cursor position in the editor
			post_jump_cmd = "normal! zz",

			keymaps = {
				-- Pick which window to jump the symbol into (aerial stays open)
				["w"] = {
					callback = function()
						local idx = vim.api.nvim_win_get_cursor(0)[1]
						local ok, picker = pcall(require, "window-picker")
						if not ok then
							require("aerial").select({ index = idx })
							return
						end
						local win = picker.pick_window({
							filter_rules = {
								bo = { filetype = { "aerial", "neo-tree", "neo-tree-popup" } },
							},
						})
						if win then
							vim.api.nvim_set_current_win(win)
							require("aerial").select({ index = idx })
						end
					end,
					desc = "Jump to symbol in picked window",
				},
			},

			lsp = {
				-- If true, fetch document symbols when LSP diagnostics update.
				diagnostics_trigger_update = true,

				-- Set to false to not update the symbols when there are LSP errors
				update_when_errors = true,

				-- How long to wait (in ms) after a buffer change before updating
				-- Only used when diagnostics_trigger_update = false
				update_delay = 300,

				-- Map of LSP client name to priority. Default value is 10.
				-- Clients with higher (larger) priority will be used before those with lower priority.
				-- Set to -1 to never use the client.
				priority = {
					-- pyright = 10,
				},
			},

			-- Append LSP detail (signature / type) to each symbol name.
			-- ctx.symbol is the raw LSP DocumentSymbol; its `detail` field carries
			-- the function signature, argument list, and return type that aerial
			-- otherwise ignores.
			post_parse_symbol = function(bufnr, item, ctx)
				if ctx.backend_name == "lsp" and ctx.symbol then
					local detail = ctx.symbol.detail
					if detail and detail ~= "" then
						-- Collapse internal whitespace / newlines to a single space
						detail = vim.trim(detail:gsub("%s+", " "))
						-- Truncate very long signatures (e.g. TypeScript overloads)
						if #detail > 80 then
							detail = detail:sub(1, 77) .. "…"
						end
						item.name = item.name .. " " .. detail
					end
				end
				return true
			end,

			-- Backends in priority order; first one with results wins (no duplicates)
			backends = { "lsp", "treesitter", "markdown", "man" },

			-- Show connecting guide lines
			show_guides = true,
			guides = {
				mid_item = "├╴",
				last_item = "└╴",
				nested_top = "│ ",
				whitespace = "  ",
			},

			-- Determines line highlighting mode when multiple splits are visible.
			-- split_width   Each open window will have its cursor location marked in the
			--               aerial buffer. Each line will only be partially highlighted
			--               to indicate which window is at that location.
			-- full_width    Each open window will have its cursor location marked as a
			--               full-width highlight in the aerial buffer.
			-- last          Only the most-recently focused window will have its location
			--               marked in the aerial buffer.
			-- none          Do not show the cursor locations in the aerial window.
			highlight_mode = "split_width",

			-- Highlight the closest symbol if the cursor is not exactly on one.
			highlight_closest = true,

			-- When true, aerial will automatically close after jumping to a symbol
			close_on_select = false,

			-- The autocmds that trigger symbols update (not used for LSP backend)
			update_events = "TextChanged,InsertLeave",

			-- Control which windows and buffers aerial should ignore.
			-- Aerial will not open when these are focused, and existing aerial windows will not be updated
			ignore = {
				-- Ignore unlisted buffers. See :help buflisted
				unlisted_buffers = false,

				-- Ignore diff windows (setting to false will allow aerial in diff windows)
				diff_windows = true,

				-- List of filetypes to ignore.
				filetypes = {},

				-- Ignored buftypes.
				-- Can be one of the following:
				-- false or nil - No buftypes are ignored.
				-- "special"    - All buffers other than normal, help and man page buffers are ignored.
				-- table        - A list of buftypes to ignore. See :help buftype for the
				--                possible values.
				-- function     - A function that returns true if the buffer should be
				--                ignored or false if it should not be ignored.
				--                Takes two arguments, `bufnr` and `buftype`.
				buftypes = "special",

				-- Ignored wintypes.
				-- Can be one of the following:
				-- false or nil - No wintypes are ignored.
				-- "special"    - All windows other than normal windows are ignored.
				-- table        - A list of wintypes to ignore. See :help win_gettype() for the
				--                possible values.
				-- function     - A function that returns true if the window should be
				--                ignored or false if it should not be ignored.
				--                Takes two arguments, `winid` and `wintype`.
				wintypes = "special",
			},

			-- Use symbol tree for folding. Set to true or false to enable/disable
			-- Set to "auto" to manage folds if your previous foldmethod was 'manual'
			-- This can be a filetype map (see :help aerial-filetype-map)
			manage_folds = true,

			-- When you fold code with za, zo, or zc, update the aerial tree as well.
			-- Only works when manage_folds = true
			link_folds_to_tree = false,

			-- Fold code when you open/collapse symbols in the tree.
			-- Only works when manage_folds = true
			link_tree_to_folds = true,

			-- Set default symbol icons to use patched font icons (see https://www.nerdfonts.com/)
			-- "auto" will set it to true if nvim-web-devicons or lspkind-nvim is installed.
			nerd_font = "auto",
		},
	},
}
