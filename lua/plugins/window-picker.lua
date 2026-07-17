-- nvim-window-picker: one global config for neo-tree, snacks.picker, aerial, qf, …
-- hint = floating-big-letter draws a big letter inside each target window.

return {
	{
		"s1n7ax/nvim-window-picker",
		version = "2.*",
		opts = {
			hint = "floating-big-letter",
			filter_rules = {
				-- Include the active split so 2-pane layouts still get a prompt,
				-- and the bottom/right window is always a valid target.
				include_current_win = true,
				autoselect_one = false,
				bo = {
					filetype = {
						"neo-tree",
						"neo-tree-popup",
						"notify",
						"snacks_notif",
						"snacks_picker_input",
						"snacks_picker_list",
						"snacks_picker_preview",
						"qf",
						"aerial",
					},
					buftype = { "terminal", "quickfix" },
				},
			},
		},
		config = function(_, opts)
			require("window-picker").setup(opts)
		end,
	},
}
