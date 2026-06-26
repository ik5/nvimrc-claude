-- Flutter / Dart support via flutter-tools.nvim.
--
-- flutter-tools manages dartls itself — do NOT enable LazyVim's lang.dart extra
-- (it configures dartls via lspconfig and will conflict).
--
-- :Flutter* commands are registered only after you enter a *.dart buffer or
-- pubspec.yaml. Open any Dart file first, then :Flutter<Tab> will autocomplete.
-- Device/emulator pickers use vim.ui.select (provided by snacks_picker).
--
-- Keys (Dart buffers only):
--   <leader>Fr   run app
--   <leader>FR   hot reload
--   <leader>Fs   hot restart
--   <leader>Fq   quit running session
--   <leader>Fd   pick device
--   <leader>Fo   toggle widget outline
--   <leader>Fp   flutter pub get
--   <leader>FS   go to super (dart LSP)

return {
	{
		"nvim-flutter/flutter-tools.nvim",
		ft = { "dart" },
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			local sdk = require("config.flutter_sdk")

			require("flutter-tools").setup({
				fvm = false,
				ui = { border = "rounded" },
				widget_guides = { enabled = true },
				decorations = {
					statusline = {
						app_version = true,
						device = true,
						project_config = true,
					},
				},
				debugger = { enabled = false },
				dev_log = {
					enabled = true,
					open_cmd = "tabnew",
					notify_errors = true,
				},
				lsp = {
					settings = {
						enableSnippets = true,
						renameFilesWithClasses = "prompt",
					},
				},
			})

			local aug = vim.api.nvim_create_augroup("flutter_tools_user", { clear = true })

			local function sync_sdk(path, silent)
				local resolved = sdk.apply(path)
				if not resolved and not silent then
					vim.notify(sdk.diagnose(path), vim.log.levels.ERROR, { title = "Flutter SDK" })
				end
				return resolved
			end

			vim.api.nvim_create_autocmd("DirChanged", {
				group = aug,
				callback = function()
					sync_sdk(vim.uv.cwd(), true)
				end,
			})

			vim.api.nvim_create_user_command("FlutterSdkInfo", function()
				local resolved = sdk.resolve(vim.fn.getcwd())
				if resolved then
					vim.notify(sdk.diagnose(vim.fn.getcwd()), vim.log.levels.INFO, { title = "Flutter SDK" })
				else
					vim.notify(sdk.diagnose(vim.fn.getcwd()), vim.log.levels.ERROR, { title = "Flutter SDK" })
				end
			end, { desc = "Show resolved Flutter SDK path" })

			vim.api.nvim_create_autocmd("LspAttach", {
				group = aug,
				callback = function(ev)
					if vim.bo[ev.buf].filetype == "dart" then
						vim.lsp.document_color.enable(true, { bufnr = ev.buf })
					end
				end,
			})
		end,
	},

	-- Buffer-local Flutter keymaps + dartls guard (same pattern as go.lua).
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "dart",
				group = vim.api.nvim_create_augroup("flutter_keymaps", { clear = true }),
				callback = function(ev)
					local map = function(lhs, rhs, desc)
						vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc, silent = true })
					end

					map("<leader>Fr", "<cmd>FlutterRun<cr>", "Flutter: Run")
					map("<leader>FR", "<cmd>FlutterReload<cr>", "Flutter: Hot reload")
					map("<leader>Fs", "<cmd>FlutterRestart<cr>", "Flutter: Hot restart")
					map("<leader>Fq", "<cmd>FlutterQuit<cr>", "Flutter: Quit session")
					map("<leader>Fd", "<cmd>FlutterDevices<cr>", "Flutter: Pick device")
					map("<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", "Flutter: Toggle outline")
					map("<leader>Fp", "<cmd>FlutterPubGet<cr>", "Flutter: Pub get")
					map("<leader>FS", "<cmd>FlutterSuper<cr>", "Flutter: Go to super")
				end,
			})

			opts.servers = opts.servers or {}
			opts.servers.dartls = false
			return opts
		end,
	},

	-- Treesitter + formatter (normally provided by LazyVim's lang.dart extra).
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, { "dart" })
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				dart = { "dart_format" },
			},
		},
	},

	-- Neotest adapter (from lang.dart extra, without the dartls conflict).
	{
		"nvim-neotest/neotest",
		dependencies = { "sidlatau/neotest-dart" },
		opts = {
			adapters = {
				["neotest-dart"] = {},
			},
		},
	},
}