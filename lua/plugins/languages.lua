-- Language support not covered by LazyVim extras:
--   HTML, CSS, Bash, Makefile, AsciiDoc treesitter + LSP

return {

	-- ── Treesitter parsers ────────────────────────────────────────────────────
	-- LazyVim extras already add parsers for their own language; this adds the
	-- remaining ones (bash, html, css, make, asciidoc, etc.)
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"ngalaiko/tree-sitter-go-template",
		},

		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, {
				"bash", -- shell scripts
				"c", -- C (clangd extra only adds cpp)
				"html", -- HTML
				"css", -- CSS
				"make", -- Makefiles / GNU Make
				-- "asciidoc",      -- not yet in nvim-treesitter's supported parsers
				"comment", -- TODO / FIXME / NOTE annotations
				"regex", -- Regex literals
				"vim", -- Vimscript
				"vimdoc", -- Vim help files
			})
		end,
	},

	-- Schema store (helps jsonls + yamlls)
	{
		"b0o/SchemaStore.nvim",
		version = false, -- use latest
	},

	-- ── LSP document links ($ref navigation for YAML/JSON) ───────────────────
	-- yamlls/jsonls expose $ref targets via textDocument/documentLink, which
	-- Neovim doesn't handle natively yet. lsplinks bridges that gap.
	{
		"icholy/lsplinks.nvim",
		event = "LspAttach",
		config = function()
			local lsplinks = require("lsplinks")
			lsplinks.setup()
			-- Override gx (default) or pick something that doesn't conflict.
			-- If you use gx for URL opening, consider "gL" or "g<CR>" instead.
			vim.keymap.set("n", "gL", lsplinks.gx)
		end,
	},

	-- ── LSP: HTML, CSS, Bash (not in any LazyVim extra) ─────────────────────
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				-- HTML
				html = {},
				-- CSS / SCSS / LESS
				cssls = {},
				-- Emmet: fast HTML & CSS completions (works alongside html/cssls)
				emmet_ls = {
					filetypes = {
						"html",
						"css",
						"scss",
						"sass",
						"less",
						"javascriptreact",
						"typescriptreact",
						"svelte",
						"vue",
						"htmldjango",
					},
				},
				-- Bash
				bashls = {
					settings = {
						bashIde = {
							globPattern = "*@(.sh|.inc|.bash|.command)",
						},
					},
				},
				yamlls = {
					settings = {
						yaml = {
							validate = true,
							schemaStore = {
								enable = true, -- Let it auto-fetch when needed
								url = "https://www.schemastore.org/api/json/catalog.json",
							},
						},
					},
				},

				jsonls = {
					settings = {
						json = {
							schemas = require("schemastore").json.schemas(),
							validate = { enable = true },
						},
					},
				},
			},
		},
	},

	-- ── Mason: formatters and linters not auto-installed via lspconfig ────────
	{
		"mason-org/mason.nvim",
		opts = {
			ensure_installed = {
				"shfmt", -- bash/sh formatter
				"shellcheck", -- bash static analysis
				"emmet-ls", -- emmet HTML/CSS completions
			},
		},
	},

	-- ── Restore :TSInstallInfo lazy-load trigger ──────────────────────────────
	-- LazyVim's treesitter spec lazy-loads the plugin via events and a cmd list
	-- that doesn't include :TSInstallInfo, so the command appears missing.
	-- Adding it here tells lazy.nvim to load the plugin when it is invoked.
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
	},

	-- ── Arduino / ESP: file type hints so clangd handles .ino files ──────────
	-- clangd (from the LazyVim clangd extra) handles C/C++ for embedded targets.
	-- For proper Arduino support, create a compile_commands.json in your project
	-- (arduino-cli export compile-commands, or use arduino-language-server).
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			-- Treat .ino (Arduino) files as C++
			vim.filetype.add({
				extension = { ino = "cpp" },
			})
		end,
	},
}
