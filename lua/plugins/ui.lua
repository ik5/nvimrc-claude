-- Disable LazyVim plugins that conflict with "keep it like plain Vim/Nvim" goal

return {
	-- No startup screen / dashboard.
	-- LazyVim uses snacks.nvim for the dashboard; disable just that component.
	{ "nvimdev/dashboard-nvim", enabled = false }, -- kept in case an older LazyVim is installed
	{
		"folke/snacks.nvim",
		opts = {
			dashboard = { enabled = false },
			notifier = {
				timeout = (function()
					local v = vim.env.DEBUG_MESSAGES
					if v == nil then
						return 60000
					end
					local n = tonumber(v)
					return n and n or 90000
				end)(),
			},

			indent = {
				enabled = true,
				only_current = false,
				only_scope = false,
				char = "│",
				animated = {
					enabled = false,
				},
				scope = {
					enabled = true,
					char = "┊",
				},
			},
		},
	},

	-- No floating cmdline / message UI — keep the standard bottom cmdline.
	-- Disabling noice also removes the floating notification popups it drives.
	{ "folke/noice.nvim", enabled = false },

	-- With noice gone, nvim-notify is just a standalone notifier.
	-- Disable it too so notifications appear in the normal message area.
	{ "rcarriga/nvim-notify", enabled = false },
}
