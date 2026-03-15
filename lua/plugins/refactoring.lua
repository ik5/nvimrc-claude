-- Refactoring tools
--
-- Two extras are imported in lazy.lua:
--   editor.inc-rename   → <leader>cr  live-preview LSP rename (replaces default)
--   editor.refactoring  → <leader>r*  treesitter extract / inline operations
--
-- Also built-in via LazyVim + snacks:
--   <leader>cR          → rename file + update all LSP imports (willRenameFiles)
--
-- This file:
--   1. Wires the refactoring picker to snacks.picker (the LazyVim extra only
--      supports telescope/fzf; for snacks it falls back to vim.ui.select which
--      snacks overrides anyway — but we make it explicit here).
--   2. Enables type / param prompts for statically-typed languages.

return {
	{
		"ThePrimeagen/refactoring.nvim",
		opts = {
			-- Ask for the return type when extracting a function in typed languages
			prompt_func_return_type = {
				go = true,
				cpp = true,
				c = true,
				java = true,
			},
			-- Ask for parameter types when extracting a function
			prompt_func_param_type = {
				go = true,
				cpp = true,
				c = true,
				java = true,
			},
			show_success_message = true,
		},

		-- Override <leader>rs to use snacks.picker when available
		keys = {
			{
				"<leader>rs",
				function()
					-- snacks picker is our active picker; use vim.ui.select which
					-- snacks overrides with its own floating picker automatically
					require("refactoring").select_refactor()
				end,
				mode = { "n", "x" },
				desc = "Refactor (pick)",
			},
		},
	},
}
