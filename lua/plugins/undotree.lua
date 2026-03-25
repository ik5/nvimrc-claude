-- Undo tree panel: visualise the full undo branch history.
--
-- Persistent undo is already active:
--   undofile = true  (LazyVim default)
--   undodir  = ~/tmp/vim_undo/  (options.lua) — files survive across sessions
--
-- Two complementary tools:
--   <F6>        mbbill/undotree – full tree panel + diff, navigate any branch
--   <leader>su  snacks.picker.undo() – quick fuzzy list of recent undo states

return {
	{
		"mbbill/undotree",
		cmd = { "UndotreeToggle", "UndotreeShow", "UndotreeHide" },
		keys = {
			{ "<F6>", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undo Tree" },
		},
		init = function()
			-- Layout 4
			vim.g.undotree_WindowLayout = 4
			vim.g.undotree_SplitWidth = 35
			vim.g.undotree_DiffpanelHeight = 12
			vim.g.undotree_DiffpanelHeight = 15
			-- Focus the undo-tree window when it opens
			vim.g.undotree_SetFocusWhenToggle = 0
			-- Compact timestamps (relative: "5 minutes ago" style)
			vim.g.undotree_ShortIndicators = 0
			vim.g.undotree_RelativeTimestamp = 1
			-- Highlight the changed region in the diff panel
			vim.g.undotree_HighlightChangedText = 1
			vim.g.undotree_HighlightChangedWithSign = 1
		end,
	},
}
