-- AI integration
--
-- TWO plugins, two different roles:
--
--   claudecode.nvim  (coder/claudecode.nvim)
--     Implements the same WebSocket/MCP protocol as the official VS Code
--     Claude Code extension.  When you run `claude` in a terminal, it
--     connects to Neovim and can read/write buffers, show diffs, etc.
--     Keys live under <leader>a (lowercase).
--
--   avante.nvim  (yetone/avante.nvim)
--     Cursor-like inline AI: side-by-side chat panel, inline edits,
--     diff review — using the Anthropic API directly.
--     Requires ANTHROPIC_API_KEY in environment.
--     Keys live under <leader>A (uppercase) to avoid clash with claudecode.
--
-- Both are lazy: nothing loads until you press a key or run a command.

return {

	-- ── claudecode.nvim ───────────────────────────────────────────────────────
	-- Keep the LazyVim extra's keymaps as-is (<leader>a prefix).
	-- The WebSocket server starts on first use.
	{
		"coder/claudecode.nvim",
		-- Defer until a key is pressed; the LazyVim extra already sets keys,
		-- but setting lazy=true here ensures it doesn't start at boot.
		lazy = true,
	},

	-- ── avante.nvim ───────────────────────────────────────────────────────────
	{
		"yetone/avante.nvim",
		opts = {
			-- Use Claude via the Anthropic API (needs ANTHROPIC_API_KEY)
			provider = "claude",
			providers = {
				claude = {
					endpoint = "https://api.anthropic.com",
					model = "claude-sonnet-4-6",
					extra_request_body = {
						temperature = 0,
						max_tokens = 8192,
					},
				},
			},
		},

		-- ── Remap <leader>a* → <leader>A* to avoid claudecode conflicts ──────
		-- The LazyVim avante extra maps many <leader>a* keys that collide with
		-- claudecode's <leader>a* keys.  We nullify the originals and re-add
		-- them all under <leader>A.
		keys = {
			-- Remove conflicting <leader>a* bindings
			{ "<leader>aa", false },
			{ "<leader>ac", false },
			{ "<leader>ae", false },
			{ "<leader>af", false },
			{ "<leader>ah", false },
			{ "<leader>am", false },
			{ "<leader>an", false },
			{ "<leader>ap", false },
			{ "<leader>ar", false },
			{ "<leader>as", false },
			{ "<leader>at", false },

			-- Re-add under <leader>A* (group label)
			{ "<leader>A", "", desc = "+avante", mode = { "n", "v" } },
			{ "<leader>Aa", "<cmd>AvanteAsk<CR>", desc = "Ask Avante" },
			{ "<leader>Ac", "<cmd>AvanteChat<CR>", desc = "Chat with Avante" },
			{ "<leader>Ae", "<cmd>AvanteEdit<CR>", desc = "Edit with Avante", mode = { "n", "v" } },
			{ "<leader>Af", "<cmd>AvanteFocus<CR>", desc = "Focus Avante" },
			{ "<leader>Ah", "<cmd>AvanteHistory<CR>", desc = "Avante History" },
			{ "<leader>Am", "<cmd>AvanteModels<CR>", desc = "Select Avante Model" },
			{ "<leader>An", "<cmd>AvanteChatNew<CR>", desc = "New Avante Chat" },
			{ "<leader>Ap", "<cmd>AvanteSwitchProvider<CR>", desc = "Switch Avante Provider" },
			{ "<leader>Ar", "<cmd>AvanteRefresh<CR>", desc = "Refresh Avante" },
			{ "<leader>As", "<cmd>AvanteStop<CR>", desc = "Stop Avante" },
			{ "<leader>At", "<cmd>AvanteToggle<CR>", desc = "Toggle Avante" },
		},
	},

	-- in lua/plugins/ai.lua, add alongside the existing claudecode/avante specs:

	{
		"nickjvandyke/opencode.nvim",
		cond = function()
			return vim.fn.executable("opencode") == 1
		end,
		dependencies = { "folke/snacks.nvim" },
		keys = {
			{
				"<leader>oo",
				function()
					require("snacks.terminal").toggle("opencode --port", {
						win = { position = "right", enter = false },
					})
				end,
				desc = "Toggle opencode",
			},
			{
				"<leader>oa",
				function()
					require("opencode").ask()
				end,
				desc = "Ask opencode",
			},
			{
				"<leader>os",
				function()
					require("opencode").select()
				end,
				mode = { "n", "v" },
				desc = "Select opencode action",
			},
		},
		config = function()
			local opencode_cmd = "opencode --port"
			local snacks_terminal_opts = { win = { position = "right", enter = false } }

			vim.g.opencode_opts = {
				server = {
					start = function()
						require("snacks.terminal").open(opencode_cmd, snacks_terminal_opts)
					end,
					stop = function()
						require("snacks.terminal").get(opencode_cmd, snacks_terminal_opts):close()
					end,
					toggle = function()
						require("snacks.terminal").toggle(opencode_cmd, snacks_terminal_opts)
					end,
				},
			}
			vim.o.autoread = true -- required for opts.events.reload
		end,
	},
}
