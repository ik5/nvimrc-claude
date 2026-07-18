-- OpenAPI / Swagger schema support on top of LazyVim lang.yaml + lang.json.
--
-- LazyVim already:
--   • installs yamlls / jsonls
--   • loads SchemaStore.nvim schemas in before_init
--   • disables yamlls built-in schemaStore (must stay disabled)
--
-- Why not SchemaStore's openapi-3.X.json?
--   That entry is a tiny if/then dispatcher (~1KB) that $ref's the real OAS
--   schemas. yamlls can still *validate* via those refs, but *completion*
--   against conditional/$ref wrappers is unreliable. We use the full official
--   OAS JSON Schemas (they expose top-level `properties`).
--
-- Why absolute-path binding instead of broad globs?
--   If two schemas match the same file (e.g. thin store entry + full 3.1, or
--   3.0 + 3.1), yamlls validation may still work while completion breaks.
--   On LspAttach we bind exactly one full schema to the buffer path.
--
-- $ref navigation (reading workflow — see lua/config/openapi_nav.lua):
--   K    preview local $ref target in a float (falls back to LSP hover)
--   gd   jump to local $ref target (falls back to LSP definition)
--   gR   force OpenAPI $ref preview
--   gL   lsplinks (generic LSP document links)
--
-- Manual override (first line of a YAML file):
--   # yaml-language-server: $schema=https://spec.openapis.org/oas/3.1/schema/2022-10-07
-- JSON can use:
--   "$schema": "https://spec.openapis.org/oas/3.1/schema/2022-10-07"
-- Or run: :OpenApiSchema [3.1|3.0|2]

local OPENAPI30_URL = "https://spec.openapis.org/oas/3.0/schema/2024-10-18"
local OPENAPI31_URL = "https://spec.openapis.org/oas/3.1/schema/2022-10-07"
local SCHEMAstore_OPENAPI_THIN = "https://www.schemastore.org/openapi-3.X.json"
local SWAGGER2_URL = "https://spec.openapis.org/oas/2.0/schema/2017-08-27"

local ALL_OPENAPI_URLS = {
	OPENAPI30_URL,
	OPENAPI31_URL,
	SCHEMAstore_OPENAPI_THIN,
	SWAGGER2_URL,
}

--- @param lines string[]
--- @return "openapi30"|"openapi31"|"swagger2"|nil
local function detect_openapi_kind(lines)
	local head = table.concat(lines, "\n", 1, math.min(#lines, 40))
	if head:match("[\"']?swagger[\"']?%s*:%s*[\"']?2%.0") then
		return "swagger2"
	end
	if head:match("[\"']?openapi[\"']?%s*:%s*[\"']?3%.0") then
		return "openapi30"
	end
	if head:match("[\"']?openapi[\"']?%s*:%s*[\"']?3%.") then
		return "openapi31"
	end
	return nil
end

--- Filename heuristic when the body has no openapi/swagger key yet.
--- @param path string
--- @return "openapi30"|"openapi31"|"swagger2"|nil
local function detect_openapi_filename(path)
	local name = path:lower()
	if name:match("swagger") then
		return "swagger2"
	end
	if name:match("openapi") or name:match("[/\\]api%.ya?ml$") or name:match("[/\\]api%.json$") or name:match("[/\\]spec%.ya?ml$") or name:match("[/\\]spec%.json$") then
		return "openapi31"
	end
	return nil
end

--- @param kind "openapi30"|"openapi31"|"swagger2"|nil
local function url_for_kind(kind)
	if kind == "swagger2" then
		return SWAGGER2_URL
	elseif kind == "openapi30" then
		return OPENAPI30_URL
	end
	return OPENAPI31_URL
end

--- @param schemas table
--- @param path string
local function yaml_detach_path(schemas, path)
	for _, url in ipairs(ALL_OPENAPI_URLS) do
		local existing = schemas[url]
		if type(existing) == "string" then
			if existing == path then
				schemas[url] = nil
			end
		elseif type(existing) == "table" then
			local kept = {}
			for _, m in ipairs(existing) do
				if m ~= path then
					kept[#kept + 1] = m
				end
			end
			schemas[url] = (#kept > 0) and kept or nil
		end
	end
end

--- Bind exactly one full schema to this buffer path (completion-friendly).
--- @param client vim.lsp.Client
--- @param bufnr integer
--- @param url string
local function associate_schema(client, bufnr, url)
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then
		return
	end

	client.config.settings = client.config.settings or {}

	if client.name == "yamlls" or client.name == "yaml-language-server" then
		local yaml = client.config.settings.yaml or {}
		yaml.schemas = yaml.schemas or {}

		-- Drop SchemaStore thin dispatcher entirely (breaks completion).
		yaml.schemas[SCHEMAstore_OPENAPI_THIN] = nil
		yaml_detach_path(yaml.schemas, path)

		local existing = yaml.schemas[url]
		if type(existing) == "string" then
			existing = { existing }
		elseif type(existing) ~= "table" then
			existing = {}
		else
			existing = vim.list_extend({}, existing)
		end
		if not vim.tbl_contains(existing, path) then
			existing[#existing + 1] = path
		end
		yaml.schemas[url] = existing
		yaml.completion = true
		yaml.hover = true
		yaml.validate = true
		client.config.settings.yaml = yaml
	elseif client.name == "jsonls" then
		local json = client.config.settings.json or {}
		local cleaned = {}
		for _, s in ipairs(json.schemas or {}) do
			if s.url == SCHEMAstore_OPENAPI_THIN then
				-- skip thin dispatcher
			elseif vim.tbl_contains(ALL_OPENAPI_URLS, s.url) then
				local fm = s.fileMatch or {}
				if type(fm) == "string" then
					fm = { fm }
				end
				local kept = {}
				for _, m in ipairs(fm) do
					if m ~= path and m ~= vim.fn.fnamemodify(path, ":t") then
						kept[#kept + 1] = m
					end
				end
				if #kept > 0 then
					local copy = vim.deepcopy(s)
					copy.fileMatch = kept
					cleaned[#cleaned + 1] = copy
				end
			else
				cleaned[#cleaned + 1] = s
			end
		end
		cleaned[#cleaned + 1] = { fileMatch = { path }, url = url }
		json.schemas = cleaned
		client.config.settings.json = json
	else
		return
	end

	local ok = pcall(function()
		client:notify("workspace/didChangeConfiguration", { settings = client.config.settings })
	end)
	if not ok and type(client.notify) == "function" then
		client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
	end
end

local function on_lsp_attach(args)
	local client = vim.lsp.get_client_by_id(args.data.client_id)
	if not client then
		return
	end
	if client.name ~= "yamlls"
		and client.name ~= "yaml-language-server"
		and client.name ~= "jsonls"
	then
		return
	end

	local bufnr = args.buf
	local ft = vim.bo[bufnr].filetype
	if ft ~= "yaml" and ft ~= "yml" and ft ~= "json" and ft ~= "jsonc" then
		return
	end

	local path = vim.api.nvim_buf_get_name(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 40, false)
	local kind = detect_openapi_kind(lines) or detect_openapi_filename(path)
	if not kind then
		return
	end

	associate_schema(client, bufnr, url_for_kind(kind))
end

--- @param existing function|nil
--- @param fn fun(params: any, config: any)
local function chain_before_init(existing, fn)
	return function(params, config)
		if existing then
			existing(params, config)
		end
		fn(params, config)
	end
end

--- Strip SchemaStore thin OpenAPI entry so it never attaches by filename.
local function strip_thin_openapi_yaml(schemas)
	schemas = schemas or {}
	schemas[SCHEMAstore_OPENAPI_THIN] = nil
	return schemas
end

return {
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}

			-- ── yamlls ──────────────────────────────────────────────────────────
			local yamlls = opts.servers.yamlls or {}
			yamlls.settings = yamlls.settings or {}
			yamlls.settings.yaml = yamlls.settings.yaml or {}

			yamlls.settings.yaml.validate = true
			yamlls.settings.yaml.hover = true
			yamlls.settings.yaml.completion = true
			yamlls.settings.yaml.schemaStore = vim.tbl_deep_extend("force", yamlls.settings.yaml.schemaStore or {}, {
				enable = false,
				url = "",
			})

			-- No broad OpenAPI globs here: absolute-path bind on LspAttach avoids
			-- multi-schema matches that break completion.
			yamlls.settings.yaml.schemas = strip_thin_openapi_yaml(yamlls.settings.yaml.schemas)

			yamlls.before_init = chain_before_init(yamlls.before_init, function(_, config)
				config.settings = config.settings or {}
				config.settings.yaml = config.settings.yaml or {}
				config.settings.yaml.completion = true
				config.settings.yaml.hover = true
				config.settings.yaml.validate = true
				config.settings.yaml.schemas = strip_thin_openapi_yaml(config.settings.yaml.schemas)
			end)

			opts.servers.yamlls = yamlls

			-- ── jsonls ──────────────────────────────────────────────────────────
			local jsonls = opts.servers.jsonls or {}
			jsonls.settings = jsonls.settings or {}
			jsonls.settings.json = jsonls.settings.json or {}
			jsonls.settings.json.validate = jsonls.settings.json.validate or { enable = true }

			jsonls.before_init = chain_before_init(jsonls.before_init, function(_, config)
				config.settings = config.settings or {}
				config.settings.json = config.settings.json or {}
				local filtered = {}
				for _, s in ipairs(config.settings.json.schemas or {}) do
					if s.url ~= SCHEMAstore_OPENAPI_THIN and s.name ~= "openapi.json" then
						filtered[#filtered + 1] = s
					end
				end
				config.settings.json.schemas = filtered
			end)

			opts.servers.jsonls = jsonls
		end,
	},

	{
		"neovim/nvim-lspconfig",
		init = function()
			-- K / gd for local $ref preview + jump (reading workflow)
			require("config.openapi_nav").setup()

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("openapi_schema_detect", { clear = true }),
				callback = on_lsp_attach,
			})

			-- Re-bind when the openapi version line changes (e.g. 3.0 → 3.1).
			vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
				group = vim.api.nvim_create_augroup("openapi_schema_refresh", { clear = true }),
				pattern = { "*.yaml", "*.yml", "*.json", "*.jsonc" },
				callback = function(ev)
					local lines = vim.api.nvim_buf_get_lines(ev.buf, 0, 40, false)
					local kind = detect_openapi_kind(lines)
					if not kind then
						return
					end
					local url = url_for_kind(kind)
					for _, client in ipairs(vim.lsp.get_clients({ bufnr = ev.buf })) do
						if client.name == "yamlls"
							or client.name == "yaml-language-server"
							or client.name == "jsonls"
						then
							associate_schema(client, ev.buf, url)
						end
					end
				end,
			})

			vim.api.nvim_create_user_command("OpenApiSchema", function(cmd)
				local bufnr = vim.api.nvim_get_current_buf()
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 40, false)
				local kind = detect_openapi_kind(lines)
				local a = cmd.args
				if a == "3" or a == "3.1" or a == "openapi3" or a == "openapi31" then
					kind = "openapi31"
				elseif a == "3.0" or a == "openapi30" then
					kind = "openapi30"
				elseif a == "2" or a == "swagger2" then
					kind = "swagger2"
				elseif not kind then
					kind = "openapi31"
				end
				local url = url_for_kind(kind)
				local bound = false
				for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
					if client.name == "yamlls"
						or client.name == "yaml-language-server"
						or client.name == "jsonls"
					then
						associate_schema(client, bufnr, url)
						bound = true
					end
				end
				if bound then
					vim.notify("OpenAPI schema bound: " .. url, vim.log.levels.INFO, { title = "OpenAPI" })
				else
					vim.notify("No yamlls/jsonls client on this buffer", vim.log.levels.WARN, { title = "OpenAPI" })
				end
			end, {
				nargs = "?",
				complete = function()
					return { "3", "3.1", "3.0", "2", "openapi31", "openapi30", "swagger2" }
				end,
				desc = "Bind OpenAPI 3.1 / 3.0 or Swagger 2.0 schema to the current buffer",
			})
		end,
	},
}
