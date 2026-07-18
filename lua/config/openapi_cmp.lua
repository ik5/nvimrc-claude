-- blink.cmp source: OpenAPI-aware completions that yamlls cannot provide.
--
-- yamlls + OAS JSON Schema is good for *structure* (info, paths, description,
-- content, …). It does NOT complete:
--   • HTTP status codes under `responses:` (additionalProperties — freeform keys)
--   • document-local `$ref` targets (#/components/schemas/Foo, …)
--   • often the `$ref` *key* itself (Response|Reference oneOf hides it)
--
-- This source fills those gaps for YAML and JSON OpenAPI documents.

local M = {}

local STATUS_CODES = {
	{ "default", "Default response" },
	{ "100", "Continue" },
	{ "101", "Switching Protocols" },
	{ "200", "OK" },
	{ "201", "Created" },
	{ "202", "Accepted" },
	{ "204", "No Content" },
	{ "301", "Moved Permanently" },
	{ "302", "Found" },
	{ "304", "Not Modified" },
	{ "400", "Bad Request" },
	{ "401", "Unauthorized" },
	{ "403", "Forbidden" },
	{ "404", "Not Found" },
	{ "405", "Method Not Allowed" },
	{ "409", "Conflict" },
	{ "410", "Gone" },
	{ "415", "Unsupported Media Type" },
	{ "422", "Unprocessable Entity" },
	{ "429", "Too Many Requests" },
	{ "500", "Internal Server Error" },
	{ "502", "Bad Gateway" },
	{ "503", "Service Unavailable" },
	{ "504", "Gateway Timeout" },
}

local COMPONENT_SECTIONS = {
	"schemas",
	"responses",
	"parameters",
	"examples",
	"requestBodies",
	"headers",
	"securitySchemes",
	"links",
	"callbacks",
	"pathItems",
}

local Kind = vim.lsp.protocol.CompletionItemKind

local function is_openapi_buf(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 40, false)
	local head = table.concat(lines, "\n")
	return head:find("openapi%s*:") ~= nil or head:find('openapi"%s*:') ~= nil or head:find("swagger%s*:%s*['\"]?2") ~= nil
end

local function line_indent(line)
	return #(line:match("^(%s*)") or "")
end

--- Collect component names from the buffer (YAML indent scan + JSON object scan).
--- @param bufnr integer
--- @return table<string, string[]>
local function collect_components(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local out = {}
	for _, sec in ipairs(COMPONENT_SECTIONS) do
		out[sec] = {}
	end

	local function add(sec, name)
		if not name or name == "" or name:sub(1, 1) == "$" then
			return
		end
		local list = out[sec]
		if list and not vim.tbl_contains(list, name) then
			list[#list + 1] = name
		end
	end

	-- ── YAML: find `components:` then section keys then direct children only ──
	local i = 1
	while i <= #lines do
		local line = lines[i]
		local content = vim.trim(line)
		if content:match("^components%s*:") or content:match('^"components"%s*:') then
			local base = line_indent(line)
			i = i + 1
			while i <= #lines do
				local l = lines[i]
				local ind = line_indent(l)
				local c = vim.trim(l)
				if c ~= "" and not c:match("^#") and ind <= base then
					break -- left components block
				end
				-- section header under components (schemas:, responses:, …)
				local sec
				for _, s in ipairs(COMPONENT_SECTIONS) do
					if c:match("^" .. s .. "%s*:") or c:match('^"' .. s .. '"%s*:') then
						sec = s
						break
					end
				end
				if sec then
					local sec_ind = ind
					i = i + 1
					local name_ind
					while i <= #lines do
						local l2 = lines[i]
						local ind2 = line_indent(l2)
						local c2 = vim.trim(l2)
						if c2 ~= "" and not c2:match("^#") and ind2 <= sec_ind then
							i = i - 1 -- reprocess this line as possible next section
							break
						end
						if c2 ~= "" and not c2:match("^#") and ind2 > sec_ind then
							if not name_ind then
								name_ind = ind2
							end
							if ind2 == name_ind then
								local name = c2:match("^([%w%._-]+)%s*:") or c2:match('^"([%w%._-]+)"%s*:')
								add(sec, name)
							end
						end
						i = i + 1
					end
				end
				i = i + 1
			end
		else
			i = i + 1
		end
	end

	-- ── JSON: "components": { "schemas": { "Foo": ... } } ──
	local text = table.concat(lines, "\n")
	local comp = text:match('"components"%s*:%s*(%b{})')
	if comp then
		for _, sec in ipairs(COMPONENT_SECTIONS) do
			local block = comp:match('"' .. sec .. '"%s*:%s*(%b{})')
			if block then
				-- only top-level keys: replace nested objects/arrays then scan keys
				local shallow = block:gsub("%b{}", "{}")
				shallow = shallow:gsub("%b[]", "[]")
				for name in shallow:gmatch('"([%w%._-]+)"%s*:') do
					add(sec, name)
				end
			end
		end
	end

	return out
end

-- Exposed for debugging / tests
M.collect_components = collect_components

--- @return boolean under_responses, integer|nil responses_indent
local function under_responses_key(lines, row0)
	local cur_indent = line_indent(lines[row0 + 1] or "")
	for i = row0, 0, -1 do
		local line = lines[i + 1] or ""
		if not line:match("^%s*#") and not line:match("^%s*$") then
			local ind = line_indent(line)
			if line:match("^%s*responses%s*:") or line:match('"responses"%s*:') then
				if cur_indent > ind then
					return true, ind
				end
				return false, nil
			end
		end
	end
	return false, nil
end

local function is_response_status_context(lines, row0, col)
	local under, resp_indent = under_responses_key(lines, row0)
	if not under or not resp_indent then
		return false
	end
	local line = lines[row0 + 1] or ""
	local ind = line_indent(line)
	if ind <= resp_indent then
		return false
	end

	-- If a parent status-code key is above us at shallower indent, we're in its body.
	for i = row0 - 1, 0, -1 do
		local l = lines[i + 1] or ""
		if not l:match("^%s*#") and not l:match("^%s*$") then
			local li = line_indent(l)
			if li <= resp_indent then
				break
			end
			if li < ind then
				local key = l:match("^%s*['\"]?([%w$]+)['\"]?%s*:")
				if key then
					if key == "default" or key:match("^%d%d%d$") then
						return false
					end
					if key == "description" or key == "content" or key == "headers" or key == "links" or key == "$ref" then
						return false
					end
				end
				break
			end
		end
	end

	-- Value side of a key (after colon) is not a status-code key position.
	local colon = line:find(":")
	if colon and col > colon then
		return false
	end
	return true
end

local function is_ref_value_context(line, col)
	local before = line:sub(1, col)
	return before:match("%$ref%s*:%s*['\"]?[^'\"]*$") ~= nil
end

local function item(label, opts)
	opts = opts or {}
	return {
		label = label,
		kind = opts.kind or Kind.Value,
		detail = opts.detail,
		documentation = opts.documentation and {
			kind = "markdown",
			value = opts.documentation,
		} or nil,
		insertText = opts.insertText or label,
		insertTextFormat = opts.snippet and vim.lsp.protocol.InsertTextFormat.Snippet
			or vim.lsp.protocol.InsertTextFormat.PlainText,
		filterText = opts.filterText or label,
		sortText = opts.sortText or label,
	}
end

function M.new()
	return setmetatable({}, { __index = M })
end

function M:enabled()
	local ft = vim.bo.filetype
	if ft ~= "yaml" and ft ~= "yml" and ft ~= "json" and ft ~= "jsonc" then
		return false
	end
	return is_openapi_buf(0)
end

function M:get_trigger_characters()
	return { "'", '"', "/", "#", ":", "$", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
end

function M:get_completions(context, callback)
	if not self:enabled() then
		callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
		return function() end
	end

	local bufnr = context.bufnr or 0
	local row = context.cursor[1] - 1
	local col = context.cursor[2]
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local line = lines[row + 1] or ""
	local items = {}
	local is_json = vim.bo[bufnr].filetype:match("json") ~= nil

	if is_ref_value_context(line, col) then
		local components = collect_components(bufnr)
		local before = line:sub(1, col)
		local prefix = before:match("%$ref%s*:%s*['\"]?(.*)$") or ""
		prefix = vim.trim(prefix)
		local has_quote = before:match("%$ref%s*:%s*['\"]") ~= nil

		local function add_ref(path, detail)
			if prefix ~= "" and path:sub(1, #prefix) ~= prefix and not path:find(prefix, 1, true) then
				return
			end
			local insert = path
			if not has_quote then
				insert = is_json and ('"' .. path .. '"') or ("'" .. path .. "'")
			end
			items[#items + 1] = item(path, {
				kind = Kind.Reference,
				detail = detail,
				insertText = insert,
				filterText = path,
				sortText = "0" .. path,
				documentation = "OpenAPI local reference → `" .. path .. "`",
			})
		end

		for _, sec in ipairs(COMPONENT_SECTIONS) do
			for _, name in ipairs(components[sec] or {}) do
				add_ref("#/components/" .. sec .. "/" .. name, "components." .. sec)
			end
		end

		-- Section prefixes while typing the pointer
		if prefix == "" or prefix:sub(1, 1) == "#" then
			for _, sec in ipairs(COMPONENT_SECTIONS) do
				local p = "#/components/" .. sec .. "/"
				if prefix == "" or p:sub(1, #prefix) == prefix then
					items[#items + 1] = item(p, {
						kind = Kind.Folder,
						detail = "component section",
						sortText = "1" .. p,
					})
				end
			end
		end
	elseif is_response_status_context(lines, row, col) then
		local partial = line:match("^%s*['\"]?([%w]*)$") or ""
		for _, entry in ipairs(STATUS_CODES) do
			local code, desc = entry[1], entry[2]
			if partial == "" or code:sub(1, #partial) == partial then
				local insert
				if is_json then
					insert = '"' .. code .. '": {\n  "$ref": "#/components/responses/$0"\n}'
				else
					local key = (code == "default") and "default" or ("'" .. code .. "'")
					insert = key .. ":\n  $ref: '#/components/responses/$0'"
				end
				items[#items + 1] = item(code, {
					kind = Kind.EnumMember,
					detail = desc,
					insertText = insert,
					snippet = true,
					filterText = code .. " " .. desc,
					sortText = (code == "default") and "999" or code,
					documentation = "**HTTP " .. code .. "** — " .. desc,
				})
			end
		end
	else
		-- Suggest $ref key on empty/partial property lines under responses bodies
		local under = under_responses_key(lines, row)
		local partial_key = line:match("^%s*(%$?[%w]*)$")
		if under and partial_key and ("$ref"):sub(1, #partial_key) == partial_key then
			-- only when we're inside a status body (not status-key line)
			if not is_response_status_context(lines, row, col) then
				local insert = is_json and '"$ref": "#/components/schemas/$0"' or "$ref: '#/components/schemas/$0'"
				items[#items + 1] = item("$ref", {
					kind = Kind.Keyword,
					detail = "OpenAPI Reference",
					insertText = insert,
					snippet = true,
					documentation = "Reference a component via JSON Pointer",
				})
			end
		end
	end

	callback({
		is_incomplete_forward = false,
		is_incomplete_backward = false,
		items = items,
	})
	return function() end
end

return M
