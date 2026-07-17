-- OpenAPI / Swagger schema support on top of LazyVim lang.yaml + lang.json.
--
-- LazyVim already:
--   • installs yamlls / jsonls
--   • loads SchemaStore.nvim schemas in before_init
--   • disables yamlls built-in schemaStore (must stay disabled)
--
-- SchemaStore only matches exact names: openapi.yaml / openapi.json / swagger.json.
-- This file:
--   1. Broadens fileMatch globs for OpenAPI 3.x and Swagger 2.0
--   2. Chains into LazyVim's before_init (does not replace SchemaStore loading)
--   3. Content-detects OpenAPI in oddly named YAML/JSON buffers and binds the schema
--   4. Documents the modeline escape hatch
--
-- $ref navigation: use gL (lsplinks.nvim in languages.lua).
--
-- Manual override (first line of a YAML file):
--   # yaml-language-server: $schema=https://www.schemastore.org/openapi-3.X.json
-- JSON can use:
--   "$schema": "https://www.schemastore.org/openapi-3.X.json"

local OPENAPI3_URL = "https://www.schemastore.org/openapi-3.X.json"
local SWAGGER2_URL = "https://spec.openapis.org/oas/2.0/schema/2017-08-27"

-- Broader than SchemaStore defaults so api/v1.yaml, foo-openapi.yaml, etc. match.
local OPENAPI3_MATCH = {
	"openapi.json",
	"openapi.yml",
	"openapi.yaml",
	"**/openapi.json",
	"**/openapi.yml",
	"**/openapi.yaml",
	"**/openapi.*.json",
	"**/openapi.*.yml",
	"**/openapi.*.yaml",
	"**/*openapi*.json",
	"**/*openapi*.yml",
	"**/*openapi*.yaml",
	"**/*-openapi.json",
	"**/*-openapi.yml",
	"**/*-openapi.yaml",
	"**/swagger.yaml", -- often OpenAPI 3 renamed; content-detect fixes OAS2
	"**/swagger.yml",
	"**/api.yaml",
	"**/api.yml",
	"**/api.json",
	"**/*-api.yaml",
	"**/*-api.yml",
	"**/*-api.json",
	"**/spec.yaml",
	"**/spec.yml",
	"**/spec.json",
}

local SWAGGER2_MATCH = {
	"swagger.json",
	"swagger.yml",
	"swagger.yaml",
	"**/swagger.json",
	"**/swagger.yml",
	"**/swagger.yaml",
	"**/*swagger*.json",
	"**/*swagger*.yml",
	"**/*swagger*.yaml",
}

--- @param lines string[]
--- @return "openapi3"|"swagger2"|nil
local function detect_openapi_kind(lines)
	local head = table.concat(lines, "\n", 1, math.min(#lines, 40))
	-- Swagger 2.0
	if head:match("[\"']?swagger[\"']?%s*:%s*[\"']?2%.0") then
		return "swagger2"
	end
	-- OpenAPI 3.x (3.0, 3.1, …)
	if head:match("[\"']?openapi[\"']?%s*:%s*[\"']?3%.") then
		return "openapi3"
	end
	return nil
end

--- Bind a schema URL to this buffer path for yamlls or jsonls.
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
		-- yamlls accepts a single path string or a list of globs as the value
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
		client.config.settings.yaml = yaml
	elseif client.name == "jsonls" then
		local json = client.config.settings.json or {}
		json.schemas = json.schemas or {}
		-- jsonls uses a list of { fileMatch = {...}, url = "..." }
		local found = false
		for _, s in ipairs(json.schemas) do
			if s.url == url then
				s.fileMatch = s.fileMatch or {}
				if type(s.fileMatch) == "string" then
					s.fileMatch = { s.fileMatch }
				end
				if not vim.tbl_contains(s.fileMatch, path) and not vim.tbl_contains(s.fileMatch, vim.fn.fnamemodify(path, ":t")) then
					s.fileMatch[#s.fileMatch + 1] = path
				end
				found = true
				break
			end
		end
		if not found then
			json.schemas[#json.schemas + 1] = {
				fileMatch = { path },
				url = url,
			}
		end
		client.config.settings.json = json
	else
		return
	end

	-- Push updated settings to the running server (0.11+ method or legacy field)
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

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 40, false)
	local kind = detect_openapi_kind(lines)
	if not kind then
		return
	end

	local url = kind == "swagger2" and SWAGGER2_URL or OPENAPI3_URL
	associate_schema(client, bufnr, url)
end

--- Chain a before_init without dropping LazyVim / SchemaStore loading.
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

return {
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}

			-- ── yamlls ──────────────────────────────────────────────────────────
			local yamlls = opts.servers.yamlls or {}
			yamlls.settings = yamlls.settings or {}
			yamlls.settings.yaml = yamlls.settings.yaml or {}

			-- Keep SchemaStore.nvim as the source of truth (LazyVim sets enable=false).
			-- Do not re-enable the built-in schemaStore catalog here.
			yamlls.settings.yaml.validate = true
			yamlls.settings.yaml.hover = true
			yamlls.settings.yaml.completion = true
			yamlls.settings.yaml.schemaStore = vim.tbl_deep_extend("force", yamlls.settings.yaml.schemaStore or {}, {
				enable = false,
				url = "",
			})

			-- Seed static broader OpenAPI matches (merged again in before_init after SchemaStore).
			yamlls.settings.yaml.schemas = vim.tbl_deep_extend("force", yamlls.settings.yaml.schemas or {}, {
				[OPENAPI3_URL] = OPENAPI3_MATCH,
				[SWAGGER2_URL] = SWAGGER2_MATCH,
			})

			yamlls.before_init = chain_before_init(yamlls.before_init, function(_, config)
				config.settings = config.settings or {}
				config.settings.yaml = config.settings.yaml or {}
				config.settings.yaml.schemas = vim.tbl_deep_extend("force", config.settings.yaml.schemas or {}, {
					[OPENAPI3_URL] = OPENAPI3_MATCH,
					[SWAGGER2_URL] = SWAGGER2_MATCH,
				})
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
				config.settings.json.schemas = config.settings.json.schemas or {}

				-- Prefer explicit OpenAPI entries (absolute path match + globs).
				-- list_extend appends; put ours first so tools that stop early still see them.
				local openapi_schemas = {
					{
						name = "openapi.json",
						description = "OpenAPI 3.x (broadened fileMatch)",
						fileMatch = OPENAPI3_MATCH,
						url = OPENAPI3_URL,
					},
					{
						name = "Swagger API 2.0",
						description = "Swagger / OpenAPI 2.0 (broadened fileMatch)",
						fileMatch = SWAGGER2_MATCH,
						url = SWAGGER2_URL,
					},
				}
				config.settings.json.schemas = vim.list_extend(openapi_schemas, config.settings.json.schemas)
			end)

			opts.servers.jsonls = jsonls
		end,
	},

	-- Content-based schema bind for files that do not match name globs
	-- (e.g. docs/service.yaml that starts with `openapi: 3.0.3`).
	{
		"neovim/nvim-lspconfig",
		init = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("openapi_schema_detect", { clear = true }),
				callback = on_lsp_attach,
			})

			vim.api.nvim_create_user_command("OpenApiSchema", function(cmd)
				local bufnr = vim.api.nvim_get_current_buf()
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 40, false)
				local kind = detect_openapi_kind(lines)
				if cmd.args == "3" or cmd.args == "openapi3" then
					kind = "openapi3"
				elseif cmd.args == "2" or cmd.args == "swagger2" then
					kind = "swagger2"
				elseif not kind then
					kind = "openapi3" -- default when forced manually
				end
				local url = kind == "swagger2" and SWAGGER2_URL or OPENAPI3_URL
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
					return { "3", "2", "openapi3", "swagger2" }
				end,
				desc = "Bind OpenAPI 3.x or Swagger 2.0 schema to the current buffer",
			})
		end,
	},
}
