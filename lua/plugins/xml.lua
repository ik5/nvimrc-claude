-- XML / DTD / XSD / SOAP / WSDL via Eclipse LemMinX (Mason: lemminx).
--
-- nvim 0.12: root_dir must be async — function(bufnr, on_dir) on_dir(path) end
-- (sync form prevents the client from attaching).
--
-- Catalogs: not required for relative schemaLocation. Needed when WSDL/XSD uses
--   <import namespace="http://…"/> without schemaLocation.
-- Generate on demand:  :XmlCatalogGenerate   (see lua/config/xml_catalog.lua)

local catalog = require("config.xml_catalog")

local function path_exists(p)
	return p and p ~= "" and vim.uv.fs_stat(p) ~= nil
end

local function find_catalogs(start_path)
	local found = {}
	local function add(p)
		if path_exists(p) and not vim.tbl_contains(found, p) then
			found[#found + 1] = p
		end
	end

	add(vim.fn.expand("~/schemas/catalog.xml"))
	add(vim.fn.expand("~/.local/share/xml/catalog.xml"))

	start_path = start_path or vim.fn.getcwd()
	for _, name in ipairs({
		"catalog.xml",
		"xml-catalog.xml",
		".lemminx/catalog.xml",
		"schemas/catalog.xml",
		"xsd/catalog.xml",
		"soap/catalog.xml",
	}) do
		local hits = vim.fs.find(name, { path = start_path, upward = true, type = "file", limit = 5 })
		for _, p in ipairs(hits) do
			add(p)
		end
	end
	return found
end

local function lemminx_settings(path)
	local start = path and vim.fs.dirname(path) or vim.fn.getcwd()
	return {
		xml = {
			preferences = {
				showSchemaDocumentationType = "all",
				quoteStyle = "double",
			},
			downloadExternalResources = {
				enabled = true,
			},
			validation = {
				enabled = true,
				schema = { enabled = "always" },
				namespaces = { enabled = "always" },
				noGrammar = "hint",
				disallowDocTypeDeclaration = false,
				resolveExternalEntities = true,
				xInclude = { enabled = true },
			},
			catalogs = find_catalogs(start),
			-- Only generic association; project mappings come from generated catalogs.
			fileAssociations = {
				{
					pattern = "**/*.xsd",
					systemId = "http://www.w3.org/2001/XMLSchema.xsd",
				},
			},
			completion = {
				autoCloseTags = true,
				autoCloseRemovesContent = true,
			},
			format = {
				enabled = true,
				splitAttributes = "preserve",
				spaceBeforeEmptyCloseTag = true,
			},
			codeLens = { enabled = true },
			symbols = {
				enabled = true,
				showReferencedGrammars = true,
			},
			server = {
				workDir = vim.fn.expand("~/.cache/lemminx"),
			},
		},
	}
end

local function refresh_lemminx(bufnr)
	bufnr = bufnr or 0
	local path = vim.api.nvim_buf_get_name(bufnr)
	local settings = lemminx_settings(path ~= "" and path or nil)
	for _, client in ipairs(vim.lsp.get_clients({ name = "lemminx" })) do
		client.config.settings = settings
		pcall(function()
			client:notify("workspace/didChangeConfiguration", { settings = settings })
		end)
	end
end

local function after_catalog_write()
	refresh_lemminx(0)
	-- Restart so catalogs are fully re-read
	for _, client in ipairs(vim.lsp.get_clients({ name = "lemminx" })) do
		client.stop(true)
	end
	vim.defer_fn(function()
		vim.cmd("edit")
	end, 200)
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, { "xml" })
			vim.filetype.add({
				extension = {
					wsdl = "xml",
					soap = "xml",
					xslt = "xslt",
					xsl = "xsl",
				},
			})
		end,
	},

	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}
			opts.servers.lemminx = vim.tbl_deep_extend("force", opts.servers.lemminx or {}, {
				cmd = { (vim.fn.exepath("lemminx") ~= "" and vim.fn.exepath("lemminx")) or "lemminx" },
				filetypes = { "xml", "xsd", "xsl", "xslt", "svg" },
				root_markers = {
					"catalog.xml",
					"xml-catalog.xml",
					".lemminx",
					"wsdl.xml",
					".git",
				},
				-- nvim 0.12 async API (sync root_dir never attaches)
				root_dir = function(bufnr, on_dir)
					local fname = vim.api.nvim_buf_get_name(bufnr)
					if fname == "" then
						on_dir(vim.fn.getcwd())
						return
					end
					local root = vim.fs.root(fname, {
						"catalog.xml",
						"xml-catalog.xml",
						".lemminx",
						"wsdl.xml",
						".git",
					})
					on_dir(root or vim.fs.dirname(fname))
				end,
				single_file_support = true,
				settings = lemminx_settings(),
			})
		end,
		init = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lemminx_attach", { clear = true }),
				callback = function(ev)
					local client = vim.lsp.get_client_by_id(ev.data.client_id)
					if not client or client.name ~= "lemminx" then
						return
					end
					refresh_lemminx(ev.buf)
					catalog.maybe_suggest(ev.buf)

					local map = function(lhs, rhs, desc)
						vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
					end

					map("gL", function()
						local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
						local results = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 1500)
						local loc
						if results then
							for _, r in pairs(results) do
								if r.result and not vim.tbl_isempty(r.result) then
									loc = r.result
									break
								end
							end
						end
						if loc then
							local list = vim.islist(loc) and loc or { loc }
							local item = list[1]
							if item then
								local uri = item.uri or item.targetUri
								local range = item.range or item.targetSelectionRange or item.targetRange
								if uri and range then
									vim.cmd("normal! m'")
									vim.lsp.util.show_document(
										{ uri = uri, range = range },
										client.offset_encoding,
										{ focus = true, reuse_win = true }
									)
									return
								end
							end
						end
						vim.notify(
							"No XML/XSD definition under cursor.\n"
								.. "If this is a namespace-only import, run :XmlCatalogGenerate",
							vim.log.levels.INFO,
							{ title = "lemminx" }
						)
					end, "XML/XSD go to definition")

					map("gR", function()
						local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
						local results = vim.lsp.buf_request_sync(0, "textDocument/hover", params, 1500)
						local contents
						if results then
							for _, r in pairs(results) do
								if r.result and r.result.contents then
									contents = r.result.contents
									break
								end
							end
						end
						if not contents then
							vim.notify(
								"Empty XML hover.\n"
									.. "• Need a bound grammar (schemaLocation, DOCTYPE, or catalog)\n"
									.. "• Namespace-only imports: :XmlCatalogGenerate\n"
									.. "• Then :XmlRestart",
								vim.log.levels.INFO,
								{ title = "lemminx" }
							)
							return
						end
						local lines = vim.lsp.util.convert_input_to_markdown_lines(contents)
						if vim.tbl_isempty(lines) then
							vim.notify("Empty XML hover content", vim.log.levels.INFO, { title = "lemminx" })
							return
						end
						vim.lsp.util.open_floating_preview(lines, "markdown", {
							border = "rounded",
							title = " XML / XSD ",
							title_pos = "center",
							max_width = 100,
							max_height = 40,
							focusable = true,
							close_events = { "CursorMoved", "BufHidden", "InsertCharPre" },
						})
					end, "XML/XSD hover documentation")
				end,
			})

			vim.api.nvim_create_autocmd("DirChanged", {
				group = vim.api.nvim_create_augroup("lemminx_catalogs", { clear = true }),
				callback = function()
					refresh_lemminx(0)
				end,
			})

			-- ── Catalog commands ───────────────────────────────────────────────
			vim.api.nvim_create_user_command("XmlCatalogGenerate", function(cmd)
				local dir = cmd.args ~= "" and cmd.args or vim.fn.getcwd()
				-- Prefer directory of current buffer when it's an xml/xsd path
				local buf = vim.api.nvim_buf_get_name(0)
				if cmd.args == "" and buf ~= "" and (buf:match("%.xml$") or buf:match("%.xsd$") or buf:match("%.wsdl$")) then
					dir = vim.fs.dirname(buf)
				end
				local ok, msg = catalog.generate(dir, { force = cmd.bang, deep = true })
				vim.notify(msg, ok and vim.log.levels.INFO or vim.log.levels.WARN, { title = "XmlCatalogGenerate" })
				if ok then
					after_catalog_write()
				end
			end, {
				nargs = "?",
				bang = true,
				complete = "dir",
				desc = "Generate catalog.xml from WSDL/XSD in dir ( ! overwrites )",
			})

			vim.api.nvim_create_user_command("XmlCatalogPreview", function(cmd)
				local dir = cmd.args ~= "" and cmd.args or vim.fn.getcwd()
				local buf = vim.api.nvim_buf_get_name(0)
				if cmd.args == "" and buf ~= "" and (buf:match("%.xml$") or buf:match("%.xsd$") or buf:match("%.wsdl$")) then
					dir = vim.fs.dirname(buf)
				end
				local result = catalog.analyze(dir, { deep = true })
				local xml = catalog.render(result)
				local scratch = vim.api.nvim_create_buf(false, true)
				vim.bo[scratch].filetype = "xml"
				vim.api.nvim_buf_set_lines(scratch, 0, -1, false, vim.split(xml, "\n"))
				vim.api.nvim_buf_set_name(scratch, "XmlCatalogPreview")
				vim.cmd("split")
				vim.api.nvim_win_set_buf(0, scratch)
				if #result.warnings > 0 then
					vim.notify(table.concat(result.warnings, "\n"), vim.log.levels.WARN, { title = "XmlCatalogPreview" })
				end
			end, {
				nargs = "?",
				complete = "dir",
				desc = "Preview generated catalog.xml without writing",
			})

			vim.api.nvim_create_user_command("XmlCatalogs", function()
				local cats = find_catalogs(vim.fn.getcwd())
				local msg = #cats == 0
						and "(none — run :XmlCatalogGenerate in a WSDL/XSD folder if imports lack schemaLocation)"
					or ("• " .. table.concat(cats, "\n• "))
				vim.notify("LemMinX catalogs:\n" .. msg, vim.log.levels.INFO, { title = "lemminx" })
			end, { desc = "Show XML catalogs used by lemminx" })

			vim.api.nvim_create_user_command("XmlRestart", function()
				for _, client in ipairs(vim.lsp.get_clients({ name = "lemminx" })) do
					client.stop(true)
				end
				vim.defer_fn(function()
					vim.cmd("edit")
					vim.notify("lemminx restarted", vim.log.levels.INFO, { title = "lemminx" })
				end, 200)
			end, { desc = "Restart lemminx" })

			vim.api.nvim_create_user_command("XmlHover", function()
				vim.cmd("normal gR")
			end, { desc = "XML/XSD hover (gR)" })

			vim.api.nvim_create_user_command("XmlGoto", function()
				vim.cmd("normal gL")
			end, { desc = "XML/XSD goto definition (gL)" })
		end,
	},

	{
		"mason-org/mason.nvim",
		opts = {
			ensure_installed = { "lemminx" },
		},
	},
}
