-- OpenAPI local $ref navigation for reading specs.
--
-- yamlls does not resolve document-local OpenAPI $refs for hover / definition.
-- Without this, K falls through to vim.lsp.buf.hover() and Neovim reports
-- "Empty hover response" (yamlls returns an empty hover result).
--
--   K   → float preview of local $ref / component under cursor
--         (only then falls back to LSP hover; suppresses empty-hover noise)
--   gd  → jump to local $ref / component
--   gR  → force OpenAPI preview (no LSP)
--   :OpenApiHover  → same as gR

local M = {}

local function is_openapi_buf(bufnr)
	bufnr = bufnr or 0
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end
	local ft = vim.bo[bufnr].filetype
	if ft ~= "yaml" and ft ~= "yml" and ft ~= "json" and ft ~= "jsonc" then
		return false
	end
	-- Scan more than the header — some files put openapi: after comments/docs
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 80, false)
	local head = table.concat(lines, "\n")
	return head:find("openapi%s*:") ~= nil
		or head:find('openapi"%s*:') ~= nil
		or head:find("swagger%s*:%s*['\"]?2") ~= nil
end

local function line_indent(line)
	return #(line:match("^(%s*)") or "")
end

local function decode_seg(s)
	return (s:gsub("~1", "/"):gsub("~0", "~"))
end

--- @param raw string
--- @return string[]|nil
local function parse_pointer(raw)
	if not raw or raw == "" then
		return nil
	end
	raw = vim.trim(raw)
	raw = raw:gsub("^[\"']", ""):gsub("[\"']$", "")
	-- strip trailing punctuation often grabbed by <cWORD>
	raw = raw:gsub("[,;]+$", "")
	if raw:sub(1, 1) == "#" then
		raw = raw:sub(2)
	end
	if raw:sub(1, 1) == "/" then
		raw = raw:sub(2)
	end
	if raw == "" then
		return nil
	end
	local segs = {}
	for part in (raw .. "/"):gmatch("([^/]*)/") do
		if part ~= "" then
			segs[#segs + 1] = decode_seg(part)
		end
	end
	return #segs > 0 and segs or nil
end

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

--- Extract a local OpenAPI pointer from text near the cursor.
--- @return string|nil pointer including leading #/
local function ref_at_cursor(bufnr)
	bufnr = bufnr or 0
	local pos = vim.api.nvim_win_get_cursor(0)
	local row, col = pos[1], pos[2]
	local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
	local ccol = col + 1 -- 1-based for string.find

	local function normalize(ptr)
		if not ptr then
			return nil
		end
		ptr = vim.trim(ptr):gsub("^[\"']", ""):gsub("[\"']$", ""):gsub("[,;]+$", "")
		if ptr:match("^https?://") then
			return ptr
		end
		if ptr:match("^#/") then
			return ptr
		end
		if ptr:match("^#") and ptr:find("/") then
			return ptr
		end
		if ptr:match("^/?components/") then
			return ptr:sub(1, 1) == "/" and ("#" .. ptr) or ("#/" .. ptr)
		end
		return nil
	end

	-- 1) Full-line $ref patterns (YAML + JSON)
	local line_patterns = {
		"%$ref%s*:%s*['\"]([^'\"]+)['\"]",
		"%$ref%s*:%s*(#%S+)",
		"%$ref%s*:%s*([%w%./#_%-]+)",
		'"%$ref"%s*:%s*"([^"]+)"',
		'"%$ref"%s*:%s*\'([^\']+)\'',
		"'%$ref'%s*:%s*'([^']+)'",
	}
	local candidates = {}
	for _, pat in ipairs(line_patterns) do
		local start = 1
		while true do
			local s, e, capt = line:find(pat, start)
			if not s then
				break
			end
			local n = normalize(capt)
			if n then
				candidates[#candidates + 1] = { s = s, e = e, ref = n }
			end
			start = e + 1
		end
	end
	if #candidates > 0 then
		for _, c in ipairs(candidates) do
			if ccol >= c.s and ccol <= c.e then
				return c.ref
			end
		end
		return candidates[1].ref
	end

	-- 2) Any #/components/... on this line near cursor
	do
		local start = 1
		while true do
			local s, e = line:find("#/components/[%w%./_%-]+", start)
			if not s then
				break
			end
			if ccol >= s and ccol <= e + 1 then
				return normalize(line:sub(s, e))
			end
			start = e + 1
		end
		local s, e = line:find("#/components/[%w%./_%-]+")
		if s then
			return normalize(line:sub(s, e))
		end
	end

	-- 3) WORD under cursor is a pointer or component name
	local word = vim.fn.expand("<cWORD>")
	local n = normalize(word)
	if n then
		return n
	end
	-- strip quotes from cword
	local cword = vim.fn.expand("<cword>")
	n = normalize(cword)
	if n then
		return n
	end

	-- 4) Bare component name → try #/components/<section>/<name>
	if cword:match("^[%w%._-]+$") and #cword > 0 then
		return { component_name = cword }
	end

	return nil
end

local function is_key_line(line, name)
	local c = vim.trim(line)
	if c:match("^#") then
		return false
	end
	local esc = vim.pesc(name)
	return c:match("^" .. esc .. "%s*:") ~= nil
		or c:match("^['\"]" .. esc .. "['\"]%s*:") ~= nil
		or c:match('^"' .. esc .. '"%s*:') ~= nil
end

--- @return integer|nil, integer|nil
local function locate_pointer(bufnr, pointer)
	local segs = parse_pointer(pointer)
	if not segs then
		return nil
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local search_from = 1
	local parent_indent = -1

	for si, seg in ipairs(segs) do
		local found_line, key_indent
		for i = search_from, #lines do
			local line = lines[i]
			local ind = line_indent(line)
			local c = vim.trim(line)
			if c ~= "" and not c:match("^#") then
				if ind > parent_indent and is_key_line(line, seg) then
					found_line = i
					key_indent = ind
					search_from = i + 1
					parent_indent = ind
					break
				elseif si > 1 and ind <= parent_indent then
					break
				end
			end
		end
		if not found_line then
			return nil
		end
		if si == #segs then
			local end_line = found_line
			for j = found_line + 1, #lines do
				local l2 = lines[j]
				local c2 = vim.trim(l2)
				if c2 ~= "" and not c2:match("^#") then
					if line_indent(l2) <= key_indent then
						break
					end
					end_line = j
				elseif c2 == "" then
					local k = j + 1
					while k <= #lines and vim.trim(lines[k]) == "" do
						k = k + 1
					end
					if k <= #lines and line_indent(lines[k]) > key_indent then
						end_line = j
					else
						break
					end
				end
			end
			return found_line, end_line
		end
	end
	return nil
end

--- Find first matching #/components/<section>/<name>
local function locate_component_name(bufnr, name)
	for _, sec in ipairs(COMPONENT_SECTIONS) do
		local s, e = locate_pointer(bufnr, "#/components/" .. sec .. "/" .. name)
		if s then
			return s, e, "#/components/" .. sec .. "/" .. name
		end
	end
	return nil
end

--- @return table|nil
function M.resolve_ref(bufnr)
	bufnr = bufnr or 0
	if not is_openapi_buf(bufnr) then
		return nil
	end

	local ref = ref_at_cursor(bufnr)
	if not ref then
		return nil
	end

	-- bare component name table
	if type(ref) == "table" and ref.component_name then
		local s, e, ptr = locate_component_name(bufnr, ref.component_name)
		if not s then
			return nil -- not an openapi component; let LSP try
		end
		return {
			ref = ptr,
			lines = vim.api.nvim_buf_get_lines(bufnr, s - 1, e, false),
			start = s,
			finish = e,
		}
	end

	if type(ref) ~= "string" then
		return nil
	end

	if ref:match("^https?://") then
		return { err = "external", ref = ref }
	end
	if ref:match("%.ya?ml$") or ref:match("%.json$") then
		return { err = "external", ref = ref }
	end

	local ptr = ref
	if not ptr:match("^#") then
		if ptr:sub(1, 1) ~= "/" then
			ptr = "#/" .. ptr
		else
			ptr = "#" .. ptr
		end
	end

	local s, e = locate_pointer(bufnr, ptr)
	if not s then
		return { err = "not_found", ref = ref }
	end
	return {
		ref = ref,
		lines = vim.api.nvim_buf_get_lines(bufnr, s - 1, e, false),
		start = s,
		finish = e,
	}
end

local function show_preview(res)
	local ft = vim.bo.filetype
	if ft == "yml" then
		ft = "yaml"
	end
	local md_ft = (ft == "json" or ft == "jsonc") and "json" or "yaml"
	local content = vim.list_extend({
		"-- " .. res.ref,
		"-- lines " .. res.start .. "–" .. res.finish .. "  ·  gd jumps here",
		"",
	}, res.lines)

	-- Use plaintext syntax name that open_floating_preview accepts; set ft after
	local buf, win = vim.lsp.util.open_floating_preview(content, md_ft, {
		border = "rounded",
		title = " OpenAPI " .. res.ref .. " ",
		title_pos = "center",
		max_width = math.min(100, vim.o.columns - 4),
		max_height = math.min(40, vim.o.lines - 4),
		wrap = false,
		focusable = true,
		close_events = { "CursorMoved", "BufHidden", "InsertCharPre" },
	})
	if buf and vim.api.nvim_buf_is_valid(buf) then
		pcall(function()
			vim.bo[buf].filetype = md_ft
		end)
	end
	return buf, win
end

--- @return boolean handled
function M.hover()
	local res = M.resolve_ref(0)
	if not res then
		return false
	end
	if res.err == "external" then
		vim.notify("OpenAPI $ref is external:\n" .. res.ref, vim.log.levels.INFO, { title = "OpenAPI" })
		return true
	end
	if res.err == "not_found" then
		vim.notify("OpenAPI $ref not found in this file:\n" .. res.ref, vim.log.levels.WARN, { title = "OpenAPI" })
		return true
	end
	show_preview(res)
	return true
end

--- LSP hover that stays silent on empty results (avoids "Empty hover response").
local function lsp_hover_quiet()
	local params = vim.lsp.util.make_position_params(0, "utf-16")
	local results = vim.lsp.buf_request_sync(0, "textDocument/hover", params, 800)
	if not results then
		return false
	end
	for _, res in pairs(results) do
		local r = res.result
		if r and r.contents then
			local lines = vim.lsp.util.convert_input_to_markdown_lines(r.contents)
			lines = vim.split(table.concat(lines, "\n"), "\n")
			-- filter empties
			local nonempty = {}
			for _, l in ipairs(lines) do
				if vim.trim(l) ~= "" then
					nonempty[#nonempty + 1] = l
				end
			end
			if #nonempty > 0 then
				vim.lsp.util.open_floating_preview(nonempty, "markdown", {
					border = "rounded",
					title = " LSP hover ",
					title_pos = "center",
					max_width = 100,
					max_height = 40,
					focusable = true,
					close_events = { "CursorMoved", "BufHidden", "InsertCharPre" },
				})
				return true
			end
		end
	end
	return false
end

--- K handler for OpenAPI buffers.
function M.hover_smart()
	if M.hover() then
		return
	end
	if lsp_hover_quiet() then
		return
	end
	-- Nothing useful from LSP either
	vim.notify(
		"No OpenAPI $ref under cursor and LSP hover is empty.\n"
			.. "Place the cursor on a `$ref: '#/components/...'` line (or the component name), then press K.\n"
			.. "Jump with gd · force preview with gR",
		vim.log.levels.INFO,
		{ title = "OpenAPI" }
	)
end

--- @return boolean handled
function M.goto_definition()
	local res = M.resolve_ref(0)
	if not res then
		return false
	end
	if res.err == "external" then
		vim.notify("OpenAPI $ref is external (not jumpable):\n" .. res.ref, vim.log.levels.INFO, { title = "OpenAPI" })
		return true
	end
	if res.err == "not_found" then
		vim.notify("OpenAPI $ref not found in this file:\n" .. res.ref, vim.log.levels.WARN, { title = "OpenAPI" })
		return true
	end
	vim.cmd("normal! m'")
	vim.api.nvim_win_set_cursor(0, { res.start, 0 })
	vim.cmd("normal! zz")
	return true
end

local function jump_to_pointer(ptr)
	if not ptr or ptr == "" then
		return false
	end
	if not ptr:match("^#") then
		ptr = "#/" .. ptr:gsub("^/", "")
	end
	local s = select(1, locate_pointer(0, ptr))
	if not s then
		return false
	end
	vim.cmd("normal! m'")
	vim.api.nvim_win_set_cursor(0, { s, 0 })
	vim.cmd("normal! zz")
	return true
end

--- Follow link under cursor: local OpenAPI $ref first, then safe lsplinks.
--- Never xdg-open bare `#/components/...` (that was launching the OS handler).
function M.follow_link()
	-- 1) Document-local OpenAPI $ref / component name (same as :OpenApiGoto)
	if is_openapi_buf(0) then
		local res = M.resolve_ref(0)
		if res and not res.err then
			vim.cmd("normal! m'")
			vim.api.nvim_win_set_cursor(0, { res.start, 0 })
			vim.cmd("normal! zz")
			return true
		end
		if res and res.err == "not_found" then
			vim.notify("OpenAPI $ref not found in this file:\n" .. res.ref, vim.log.levels.WARN, { title = "OpenAPI" })
			return true
		end
		if res and res.err == "external" then
			vim.notify("OpenAPI $ref is external:\n" .. res.ref, vim.log.levels.INFO, { title = "OpenAPI" })
			return true
		end
	end

	-- 2) lsplinks documentLink — only file:// and https:// go to open()
	local ok, lsplinks = pcall(require, "lsplinks")
	if ok then
		local uri = lsplinks.current()
		if uri then
			if (uri:match("#/components/") or uri:match("^#/")) and is_openapi_buf(0) then
				local frag = uri:match("(#[^%s]+)$") or uri
				if jump_to_pointer(frag) then
					return true
				end
				vim.notify("OpenAPI link not found: " .. uri, vim.log.levels.WARN, { title = "OpenAPI" })
				return true
			end
			if uri:find("^file:/") or uri:find("^https?://") then
				return lsplinks.open(uri)
			end
			vim.notify(
				"LSP document link is not a local file or http URL:\n" .. uri .. "\n(not opening with the OS)",
				vim.log.levels.INFO,
				{ title = "lsplinks" }
			)
			return true
		end
	end

	vim.notify("No link / $ref under cursor", vim.log.levels.INFO, { title = "OpenAPI" })
	return false
end

--- Global maps (win over LazyVim buffer LSP maps by being the ones we re-apply last).
local function set_global_maps()
	-- Use expr-less plain maps; check buffer type at runtime.
	vim.keymap.set("n", "K", function()
		if is_openapi_buf(0) then
			M.hover_smart()
			return
		end
		vim.lsp.buf.hover()
	end, { desc = "Hover (OpenAPI $ref preview when applicable)", silent = true })

	vim.keymap.set("n", "gd", function()
		if is_openapi_buf(0) and M.goto_definition() then
			return
		end
		local ok = pcall(function()
			Snacks.picker.lsp_definitions()
		end)
		if not ok then
			vim.lsp.buf.definition()
		end
	end, { desc = "Goto definition (OpenAPI $ref when applicable)", silent = true })

	vim.keymap.set("n", "gL", function()
		M.follow_link()
	end, { desc = "Follow link / OpenAPI $ref (safe, no OS open for #/)", silent = true })

	vim.keymap.set("n", "gR", function()
		if not M.hover() then
			vim.notify("No OpenAPI $ref / component under cursor", vim.log.levels.INFO, { title = "OpenAPI" })
		end
	end, { desc = "OpenAPI $ref preview (force)", silent = true })
end

function M.attach(bufnr)
	bufnr = bufnr or 0
	if not is_openapi_buf(bufnr) then
		return
	end
	-- Buffer-local copies so they beat other buffer maps set on LspAttach
	local opts = { buffer = bufnr, silent = true, noremap = true, nowait = true }
	pcall(vim.keymap.del, "n", "K", { buffer = bufnr })
	pcall(vim.keymap.del, "n", "gd", { buffer = bufnr })
	pcall(vim.keymap.del, "n", "gL", { buffer = bufnr })

	vim.keymap.set("n", "K", function()
		M.hover_smart()
	end, vim.tbl_extend("force", opts, { desc = "OpenAPI $ref preview / LSP hover" }))

	vim.keymap.set("n", "gd", function()
		if not M.goto_definition() then
			local ok = pcall(function()
				Snacks.picker.lsp_definitions()
			end)
			if not ok then
				vim.lsp.buf.definition()
			end
		end
	end, vim.tbl_extend("force", opts, { desc = "OpenAPI $ref jump / LSP definition" }))

	vim.keymap.set("n", "gL", function()
		M.follow_link()
	end, vim.tbl_extend("force", opts, { desc = "Follow OpenAPI $ref / document link" }))

	vim.keymap.set("n", "gR", function()
		if not M.hover() then
			vim.notify("No OpenAPI $ref / component under cursor", vim.log.levels.INFO, { title = "OpenAPI" })
		end
	end, vim.tbl_extend("force", opts, { desc = "OpenAPI $ref preview (force)" }))

	vim.b[bufnr].openapi_nav = true
end

function M.setup()
	local group = vim.api.nvim_create_augroup("openapi_nav", { clear = true })

	set_global_maps()

	local function try_attach(buf)
		buf = buf or vim.api.nvim_get_current_buf()
		if vim.api.nvim_buf_is_valid(buf) and is_openapi_buf(buf) then
			M.attach(buf)
		end
	end

	vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "BufWritePost", "FileType" }, {
		group = group,
		pattern = { "*.yaml", "*.yml", "*.json", "*.jsonc", "yaml", "yml", "json", "jsonc" },
		callback = function(ev)
			vim.schedule(function()
				try_attach(ev.buf)
			end)
		end,
	})

	-- Re-apply after LazyVim/LSP buffer maps (they register on LspAttach)
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("openapi_nav_lsp", { clear = true }),
		callback = function(ev)
			vim.defer_fn(function()
				try_attach(ev.buf)
			end, 50)
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		once = true,
		callback = function()
			set_global_maps()
			try_attach(0)
		end,
	})

	vim.api.nvim_create_user_command("OpenApiHover", function()
		if not M.hover() then
			vim.notify("No OpenAPI $ref / component under cursor", vim.log.levels.INFO, { title = "OpenAPI" })
		end
	end, { desc = "Preview OpenAPI $ref target under cursor" })

	-- Alias the capitalisation users type naturally
	vim.api.nvim_create_user_command("OpenAPIHover", function()
		vim.cmd("OpenApiHover")
	end, { desc = "Alias for :OpenApiHover" })

	vim.api.nvim_create_user_command("OpenApiGoto", function()
		if not M.goto_definition() then
			vim.notify("No OpenAPI $ref / component under cursor", vim.log.levels.INFO, { title = "OpenAPI" })
		end
	end, { desc = "Jump to OpenAPI $ref target under cursor" })

	vim.api.nvim_create_user_command("OpenAPIGoto", function()
		vim.cmd("OpenApiGoto")
	end, { desc = "Alias for :OpenApiGoto" })
end

return M
