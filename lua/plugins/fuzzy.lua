-- Fuzzy finder via snacks.picker (ships with snacks.nvim, already loaded).
-- The snacks_picker extra (imported in lazy.lua) registers snacks as the
-- active LazyVim picker and wires up the default keymaps.
--
-- Result-open keys (grep, files, LSP, …) — same as neo-tree in explorer.lua:
--   <CR>   last active window (picker main)
--   <C-x>  horizontal split of a picked window (window-picker)
--   <C-v>  vertical split of a picked window (window-picker)
--   w      open in a picked window (window-picker)

local picker_open_keys = {
	input = {
		["<CR>"] = { "confirm", mode = { "n", "i" } },
		["<C-x>"] = { "wp_split", mode = { "n", "i" } },
		["<C-v>"] = { "wp_vsplit", mode = { "n", "i" } },
		["<C-s>"] = false,
		["w"] = { "wp_jump", mode = "n" },
	},
	list = {
		["<CR>"] = "confirm",
		["<C-x>"] = "wp_split",
		["<C-v>"] = "wp_vsplit",
		["<C-s>"] = false,
		["w"] = "wp_jump",
	},
}

return {
	{
		"folke/snacks.nvim",
		dependencies = { "s1n7ax/nvim-window-picker" }, -- config: lua/plugins/window-picker.lua
		opts = {
			picker = {
				actions = {
					wp_jump = function(picker)
						require("config.window_picker").snacks_open(picker)
					end,
					wp_split = function(picker)
						require("config.window_picker").snacks_open(picker, "split")
					end,
					wp_vsplit = function(picker)
						require("config.window_picker").snacks_open(picker, "vsplit")
					end,
				},
				win = {
					input = { keys = picker_open_keys.input },
					list = { keys = picker_open_keys.list },
				},
				sources = {
					grep = { jump = { reuse_win = true } },
					grep_word = { jump = { reuse_win = true } },
					grep_buffers = { jump = { reuse_win = true } },
				},
			},
		},
		keys = {

			-- ── Conflict: <leader>gd / <leader>gD ─────────────────────────────────
			{ "<leader>gd", false },
			{ "<leader>gD", false },

			{ "<leader>Gd", function()
				Snacks.picker.git_diff()
			end, desc = "Git Diff (hunks)" },
			{ "<leader>GD", function()
				Snacks.picker.git_diff({ base = "origin", group = true })
			end, desc = "Git Diff (origin)" },

			{ "<leader>gL", function()
				Snacks.picker.git_log()
			end, desc = "Git Log (all commits)" },
			{ "<leader>gll", function()
				Snacks.picker.git_log_file()
			end, desc = "Git Log (current file)" },
			{ "<leader>gb", function()
				Snacks.picker.git_branches()
			end, desc = "Git Branches" },

		},
	},
}