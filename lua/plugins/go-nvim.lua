return {
	{
		"ray-x/go.nvim",
		dependencies = { -- optional packages
			"ray-x/guihua.lua",
			"neovim/nvim-lspconfig",
			{ "nvim-treesitter/nvim-treesitter", branch = "main" },
		},
		opts = function(_, opts)
			require("go").setup(opts)
			local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*.go",
				callback = function()
					require("go.format").goimports()
				end,
				group = format_sync_grp,
			})

			-- Manage codelens manually since go.nvim's handler requires nvim nightly
			vim.api.nvim_create_autocmd("LspAttach", {
				pattern = "*.go",
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					if client and client:supports_method("textDocument/codeLens") then
						-- Initial refresh
						vim.lsp.codelens.refresh()
						-- Keep refreshing on these events
						vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "BufWritePre" }, {
							buffer = args.buf,
							callback = function()
								vim.lsp.codelens.refresh()
							end,
						})
					end
				end,
			})

			return {
				go = "go",
				goimports = "gopls",
				gofmt = "gofumpt",
				null_ls_document_formatting_disable = true,
				tag_transform = "snakecase",
				gotest_case_exact_match = true, -- true: run test with ^Testname$, false: run test with TestName
				icons = { breakpoint = "🧘", currentpos = "🏃" }, -- setup to `false` to disable icons setup
				verbose = true, -- output loginf in messages
				lsp_semantic_highlights = true, -- use highlights from gopls, disable by default as gopls/nvim not compatible
				lsp_gofumpt = true,
				lsp_keymaps = true,
				lsp_codelens = false,
				lsp_document_formatting = true,

				lsp_inlay_hints = {
					enable = true,
				},

				gocoverage_sign = "█",
				sign_priority = 5, -- change to a higher number to override other signs
				dap_debug = false,

				golangci_lint = {
					default = "standard", -- set to one of { 'standard', 'fast', 'all', 'none' }
					-- disable = {'errcheck', 'staticcheck'}, -- linters to disable empty by default
					-- enable = {'govet', 'ineffassign','revive', 'gosimple'}, -- linters to enable; empty by default
					config = nil, -- set to a config file path
					no_config = false, -- true: golangci-lint --no-config
					-- disable = {},     -- linters to disable empty by default, e.g. {'errcheck', 'staticcheck'}
					-- enable = {},      -- linters to enable; empty by default, set to e.g. {'govet', 'ineffassign','revive', 'gosimple'}
					-- enable_only = {}, -- linters to enable only; empty by default, set to e.g. {'govet', 'ineffassign','revive', 'gosimple'}
					severity = vim.diagnostic.severity.INFO, -- severity level of the diagnostics
				},
				null_ls = { -- check null-ls integration in readme
					golangci_lint = {
						method = { "NULL_LS_DIAGNOSTICS_ON_SAVE", "NULL_LS_DIAGNOSTICS_ON_OPEN" }, -- when it should run
						severity = vim.diagnostic.severity.INFO, -- severity level of the diagnostics
					},
					gotest = {
						method = { "NULL_LS_DIAGNOSTICS_ON_SAVE" }, -- when it should run
						severity = vim.diagnostic.severity.WARN, -- severity level of the diagnostics
					},
				},

				textobjects = true, -- enable default text objects through treesittter-text-objects
				test_runner = "go", -- one of {`go`,  `dlv`, `ginkgo`, `gotestsum`}
				verbose_tests = true, -- set to add verbose flag to tests deprecated, see '-v' option
				run_in_floaterm = false, -- set to true to run in a float window. :GoTermClose closes the floatterm
				-- float term recommend if you use gotestsum ginkgo with terminal color

				floaterm = { -- position
					posititon = "auto", -- one of {`top`, `bottom`, `left`, `right`, `center`, `auto`}
					width = 0.45, -- width of float window if not auto
					height = 0.98, -- height of float window if not auto
					title_colors = "monokai", -- default to nord, one of {'nord', 'tokyo', 'dracula', 'rainbow', 'solarized ', 'monokai'}
					-- can also set to a list of colors to define colors to choose from
					-- e.g {'#D8DEE9', '#5E81AC', '#88C0D0', '#EBCB8B', '#A3BE8C', '#B48EAD'}
				},

				trouble = true, -- true: use trouble to open quickfix
				test_efm = true, -- errorfomat for quickfix, default mix mode, set to true will be efm only
				luasnip = true,
			}
		end,
		event = { "CmdlineEnter" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
	},
}
