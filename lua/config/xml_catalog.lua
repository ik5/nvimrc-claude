-- Generate OASIS XML catalogs for LemMinX from local WSDL/XSD files.
--
-- Priority:
--   1. Local files on disk (every .xsd registered by basename / path / file://)
--   2. import/include schemaLocation → resolve relative to importer, then search tree
--   3. Namespace-only imports → match targetNamespace, then co-located XSDs
--   4. Skip orphans already satisfied by an *inline* schema in the same WSDL
--
-- Commands (plugins/xml.lua):
--   :XmlCatalogGenerate[!] [dir]
--   :XmlCatalogPreview [dir]

local M = {}

local SKIP_DIRS = {
	[".git"] = true,
	node_modules = true,
	[".idea"] = true,
	target = true,
	build = true,
	dist = true,
	vendor = true,
	soaupui = true, -- soapui projects
}

local function path_exists(p)
	return p and p ~= "" and vim.uv.fs_stat(p) ~= nil
end

local function abspath(p)
	if not p or p == "" then
		return p
	end
	return vim.fn.fnamemodify(p, ":p"):gsub("/+$", "")
end

local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local data = f:read("*a")
	f:close()
	return data
end

local function file_uri(abs)
	abs = abspath(abs)
	if abs:sub(1, 1) ~= "/" then
		abs = "/" .. abs:gsub("\\", "/")
	end
	return "file://" .. abs
end

local function relpath(from_dir, abs_path)
	from_dir = abspath(from_dir)
	abs_path = abspath(abs_path)
	if abs_path:sub(1, #from_dir + 1) == from_dir .. "/" or abs_path == from_dir then
		local rel = abs_path:sub(#from_dir + 2)
		return (rel ~= "" and rel) or vim.fs.basename(abs_path)
	end
	return abs_path
end

local function xml_escape(s)
	return (s:gsub("&", "&amp;"):gsub('"', "&quot;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

--- @param dir string
--- @param deep? boolean
--- @return string[]
local function list_schema_files(dir, deep)
	local out = {}
	local function walk(path, depth)
		local fd = vim.uv.fs_scandir(path)
		if not fd then
			return
		end
		while true do
			local name, typ = vim.uv.fs_scandir_next(fd)
			if not name then
				break
			end
			if name:sub(1, 1) == "." and name ~= ".lemminx" then
				goto continue
			end
			local full = path .. "/" .. name
			if typ == "directory" then
				if not SKIP_DIRS[name] and (deep or depth < 2) then
					walk(full, depth + 1)
				end
			elseif typ == "file" then
				local lower = name:lower()
				local is_schema = lower:match("%.xsd$")
					or lower:match("%.wsdl$")
					or lower:match("%.dtd$")
					or lower == "wsdl.xml"
					or (lower:match("%.xml$") and (lower:match("wsdl") or lower:match("schema") or lower:match("soap")))
				if is_schema and name ~= "catalog.xml" and name ~= "xml-catalog.xml" and not lower:match("soapui") then
					out[#out + 1] = full
				end
			end
			::continue::
		end
	end
	walk(dir, 0)
	table.sort(out)
	return out
end

--- All targetNamespace values declared on <schema> elements in a document
--- (WSDL often has several inline schemas).
local function all_target_namespaces(text)
	local set = {}
	for tns in text:gmatch('targetNamespace%s*=%s*"([^"]+)"') do
		set[tns] = true
	end
	for tns in text:gmatch("targetNamespace%s*=%s*'([^']+)'") do
		set[tns] = true
	end
	return set
end

---@class xml_catalog.Import
---@field namespace string
---@field schemaLocation? string
---@field source string

---@class xml_catalog.XsdInfo
---@field path string
---@field targetNamespace? string
---@field basenames string basename lower

local function parse_imports(path, text)
	local imports = {}
	local inline_tns = all_target_namespaces(text)

	local function add_import(ns, loc)
		imports[#imports + 1] = {
			namespace = ns or "",
			schemaLocation = loc,
			source = path,
		}
	end

	-- import / include (possibly multi-line tags)
	for tag in text:gmatch("<%s*[%w:]*import%s.->") do
		local ns = tag:match('namespace%s*=%s*"([^"]+)"') or tag:match("namespace%s*=%s*'([^']+)'")
		local loc = tag:match('schemaLocation%s*=%s*"([^"]+)"')
			or tag:match("schemaLocation%s*=%s*'([^']+)'")
			or tag:match('location%s*=%s*"([^"]+)"')
			or tag:match("location%s*=%s*'([^']+)'")
		if ns or loc then
			add_import(ns, loc)
		end
	end
	for tag in text:gmatch("<%s*[%w:]*include%s.->") do
		local loc = tag:match('schemaLocation%s*=%s*"([^"]+)"') or tag:match("schemaLocation%s*=%s*'([^']+)'")
		if loc then
			add_import("", loc)
		end
	end

	-- xsi:schemaLocation pairs (attribute may appear on root)
	for attr in text:gmatch('xsi:schemaLocation%s*=%s*"([^"]+)"') do
		local parts = {}
		for p in attr:gmatch("%S+") do
			parts[#parts + 1] = p
		end
		for i = 1, #parts - 1, 2 do
			add_import(parts[i], parts[i + 1])
		end
	end

	return imports, inline_tns
end

local function parse_xsd_info(path, text)
	if not path:lower():match("%.xsd$") then
		return nil
	end
	-- Prefer the schema root's targetNamespace (first on an xs:schema / schema tag)
	local tns
	local schema_tag = text:match("<%s*[%w:]*schema%s.->")
	if schema_tag then
		tns = schema_tag:match('targetNamespace%s*=%s*"([^"]+)"')
			or schema_tag:match("targetNamespace%s*=%s*'([^']+)'")
	end
	return {
		path = path,
		targetNamespace = tns,
		basenames = vim.fs.basename(path):lower(),
	}
end

--- Find a local file for a schemaLocation string.
---@param import_file string
---@param loc string
---@param by_basename table<string, string[]> basename → abs paths
---@param tree_files string[]
local function find_local_file(import_file, loc, by_basename, tree_files)
	if not loc or loc == "" or loc:match("^https?://") or loc:match("^file:") then
		return nil, loc and loc:match("^https?://") and "remote" or nil
	end

	local dir = vim.fs.dirname(import_file)
	local candidates = {
		abspath(dir .. "/" .. loc),
		abspath(dir .. "/" .. vim.fs.basename(loc)),
		abspath(loc),
	}
	for _, c in ipairs(candidates) do
		if path_exists(c) then
			return c, "path"
		end
	end

	-- Search scanned tree by basename
	local base = vim.fs.basename(loc):lower()
	local hits = by_basename[base]
	if hits and #hits == 1 then
		return hits[1], "basename"
	end
	if hits and #hits > 1 then
		-- Prefer same directory as importer, then nearest
		local best
		for _, h in ipairs(hits) do
			if vim.fs.dirname(h) == dir then
				return h, "basename-same-dir"
			end
			best = best or h
		end
		return best, "basename-first"
	end

	-- Fuzzy: any tree file ending with loc
	local loc_norm = loc:gsub("^%./", "")
	for _, f in ipairs(tree_files) do
		if f:sub(-#loc_norm) == loc_norm or f:lower():sub(-#base) == base then
			return f, "suffix"
		end
	end

	return nil, "missing"
end

---@class xml_catalog.Entry
---@field kind "uri"|"system"
---@field name string
---@field uri string  -- relative to catalog dir preferred; file:// also added separately
---@field note? string

local function build_entries(dir, files)
	local entries = {}
	local seen = {}
	local warnings = {}

	local function add(kind, name, target_abs, note)
		if not name or name == "" or not target_abs or target_abs == "" then
			return
		end
		if not path_exists(target_abs) and not target_abs:match("^https?://") then
			return
		end
		local key = kind .. "\0" .. name .. "\0" .. target_abs
		if seen[key] then
			return
		end
		seen[key] = true
		local uri = path_exists(target_abs) and relpath(dir, target_abs) or target_abs
		entries[#entries + 1] = { kind = kind, name = name, uri = uri, note = note }
		-- Absolute file:// helps LemMinX when cwd ≠ catalog dir
		if path_exists(target_abs) then
			local fkey = kind .. "\0" .. name .. "\0file"
			if not seen[fkey] then
				seen[fkey] = true
				entries[#entries + 1] = {
					kind = kind,
					name = name,
					uri = file_uri(target_abs),
					note = (note and (note .. " [file://]")) or "file:// absolute",
				}
			end
		end
	end

	-- Index local files
	local xsds = {}
	local by_basename = {}
	local all_imports = {}
	local inline_by_file = {}

	for _, path in ipairs(files) do
		local text = read_file(path)
		if not text then
			goto continue
		end
		local imports, inline_tns = parse_imports(path, text)
		inline_by_file[path] = inline_tns
		for _, imp in ipairs(imports) do
			all_imports[#all_imports + 1] = imp
		end
		local info = parse_xsd_info(path, text)
		if info then
			xsds[#xsds + 1] = info
		end
		local base = vim.fs.basename(path):lower()
		by_basename[base] = by_basename[base] or {}
		by_basename[base][#by_basename[base] + 1] = path
		::continue::
	end

	-- ── 1) Register every local XSD as a system id (basename + relative path) ─
	for _, path in ipairs(files) do
		if path:lower():match("%.xsd$") or path:lower():match("%.dtd$") then
			local base = vim.fs.basename(path)
			local rel = relpath(dir, path)
			add("system", base, path, "local file basename")
			add("system", "./" .. base, path, "local file ./basename")
			if rel ~= base then
				add("system", rel, path, "local file relative path")
				add("system", "./" .. rel, path, "local file ./relative")
			end
			add("system", file_uri(path), path, "local file URI as systemId")
		end
	end

	-- ── 2) XSD targetNamespace → file ───────────────────────────────────────
	for _, x in ipairs(xsds) do
		if x.targetNamespace then
			add("uri", x.targetNamespace, x.path, "targetNamespace of " .. vim.fs.basename(x.path))
		end
	end

	-- ── 3) Imports with schemaLocation → find local files ───────────────────
	local orphans = {} ---@type { ns: string, source: string }[]
	for _, imp in ipairs(all_imports) do
		if imp.schemaLocation and imp.schemaLocation ~= "" then
			if imp.schemaLocation:match("^https?://") then
				-- Prefer local copy if we already have a file with that basename
				local base = vim.fs.basename(imp.schemaLocation):lower()
				local hits = by_basename[base]
				if hits and hits[1] then
					add(
						"system",
						imp.schemaLocation,
						hits[1],
						"remote URL → local " .. vim.fs.basename(hits[1])
					)
					if imp.namespace ~= "" then
						add("uri", imp.namespace, hits[1], "namespace via local copy of remote schema")
					end
				else
					warnings[#warnings + 1] = "Remote schema (download if enabled): "
						.. imp.schemaLocation
						.. " (from "
						.. vim.fs.basename(imp.source)
						.. ")"
					if imp.namespace ~= "" then
						add("system", imp.schemaLocation, imp.schemaLocation, "remote systemId (no local file)")
					end
				end
			else
				local found, how = find_local_file(imp.source, imp.schemaLocation, by_basename, files)
				if found then
					add(
						"system",
						imp.schemaLocation,
						found,
						"schemaLocation → local (" .. (how or "?") .. ") from " .. vim.fs.basename(imp.source)
					)
					if imp.namespace ~= "" then
						add("uri", imp.namespace, found, "namespace + schemaLocation from " .. vim.fs.basename(imp.source))
					end
				else
					warnings[#warnings + 1] = "schemaLocation not found on disk: "
						.. imp.schemaLocation
						.. " (from "
						.. vim.fs.basename(imp.source)
						.. ")"
				end
			end
		elseif imp.namespace and imp.namespace ~= "" then
			-- Namespace-only: skip if same document already defines that tns inline
			local inline = inline_by_file[imp.source] or {}
			if inline[imp.namespace] then
				warnings[#warnings + 1] = "import namespace "
					.. imp.namespace
					.. " is already defined by an inline <schema> in "
					.. vim.fs.basename(imp.source)
					.. " (no external file needed)"
			else
				orphans[#orphans + 1] = { ns = imp.namespace, source = imp.source }
			end
		end
	end

	-- ── 4) Orphan namespaces → local XSD by tns / co-location / single XSD ──
	local by_tns = {}
	local no_tns = {}
	for _, x in ipairs(xsds) do
		if x.targetNamespace and x.targetNamespace ~= "" then
			by_tns[x.targetNamespace] = x.path
		else
			no_tns[#no_tns + 1] = x.path
		end
	end

	local resolved_orphans = {}
	local unresolved = {}
	local seen_orphan = {}

	for _, o in ipairs(orphans) do
		if seen_orphan[o.ns] then
			goto next_orphan
		end
		seen_orphan[o.ns] = true

		if by_tns[o.ns] then
			add("uri", o.ns, by_tns[o.ns], "namespace-only import matched targetNamespace")
			resolved_orphans[o.ns] = by_tns[o.ns]
			goto next_orphan
		end

		-- XSDs in the same directory as the importer
		local src_dir = vim.fs.dirname(o.source)
		local colocated = {}
		for _, x in ipairs(xsds) do
			if vim.fs.dirname(x.path) == src_dir then
				colocated[#colocated + 1] = x.path
			end
		end
		if #colocated == 1 then
			add(
				"uri",
				o.ns,
				colocated[1],
				"namespace-only import → sole XSD next to " .. vim.fs.basename(o.source)
			)
			resolved_orphans[o.ns] = colocated[1]
			goto next_orphan
		end

		if #colocated > 1 then
			-- Prefer names containing message/body/type/schema
			local best, score = nil, -1
			for _, p in ipairs(colocated) do
				local b = vim.fs.basename(p):lower()
				local s = 0
				if b:find("message", 1, true) or b:find("body", 1, true) then
					s = s + 3
				end
				if b:find("type", 1, true) or b:find("schema", 1, true) then
					s = s + 2
				end
				if s > score then
					score, best = s, p
				end
			end
			if best and score > 0 then
				add("uri", o.ns, best, "namespace-only import → co-located XSD (name heuristic)")
				resolved_orphans[o.ns] = best
				goto next_orphan
			end
		end

		if #no_tns == 1 then
			add("uri", o.ns, no_tns[1], "namespace-only import → only XSD without targetNamespace")
			resolved_orphans[o.ns] = no_tns[1]
			goto next_orphan
		end

		unresolved[#unresolved + 1] = o.ns
		::next_orphan::
	end

	if #entries == 0 then
		warnings[#warnings + 1] = "No catalog mappings under " .. dir
	end

	return {
		dir = dir,
		entries = entries,
		warnings = warnings,
		xsds = vim.tbl_map(function(x)
			return x.path
		end, xsds),
		local_files = files,
		orphans_resolved = resolved_orphans,
		orphans_unresolved = unresolved,
	}
end

--- @param dir? string
--- @param opts? { deep?: boolean }
function M.analyze(dir, opts)
	opts = opts or {}
	dir = abspath(dir or vim.fn.getcwd())
	local files = list_schema_files(dir, opts.deep ~= false)
	return build_entries(dir, files)
end

function M.render(result)
	local lines = {
		[[<?xml version="1.0"?>]],
		[[<!--]],
		[[  Generated by Neovim :XmlCatalogGenerate]],
		[[  Directory: ]] .. result.dir,
		[[  Date: ]] .. os.date("%Y-%m-%d %H:%M"),
		[[]],
		[[  Local-file first: every .xsd is registered by basename + relative path,]],
		[[  then import schemaLocation is resolved on disk, then namespace-only imports.]],
		[[  Re-run after adding schemas.  Reload: :XmlRestart]],
		[[-->]],
		[[<catalog xmlns="urn:oasis:names:tc:entity:xmlns:xml:catalog">]],
		"",
	}

	-- Group: system (local files) first, then uri
	local systems, uris = {}, {}
	for _, e in ipairs(result.entries) do
		if e.kind == "system" then
			systems[#systems + 1] = e
		else
			uris[#uris + 1] = e
		end
	end

	if #systems > 0 then
		lines[#lines + 1] = "  <!-- ── Local files (systemId → path) ─────────────────────────────── -->"
		lines[#lines + 1] = ""
		for _, e in ipairs(systems) do
			if e.note then
				lines[#lines + 1] = "  <!-- " .. e.note:gsub("%-%-", "- -") .. " -->"
			end
			lines[#lines + 1] = string.format(
				'  <system systemId="%s"\n          uri="%s"/>',
				xml_escape(e.name),
				xml_escape(e.uri)
			)
			lines[#lines + 1] = ""
		end
	end

	if #uris > 0 then
		lines[#lines + 1] = "  <!-- ── Namespaces (uri name → path) ──────────────────────────────── -->"
		lines[#lines + 1] = ""
		for _, e in ipairs(uris) do
			if e.note then
				lines[#lines + 1] = "  <!-- " .. e.note:gsub("%-%-", "- -") .. " -->"
			end
			lines[#lines + 1] = string.format(
				'  <uri name="%s"\n       uri="%s"/>',
				xml_escape(e.name),
				xml_escape(e.uri)
			)
			lines[#lines + 1] = ""
		end
	end

	if result.local_files and #result.local_files > 0 then
		lines[#lines + 1] = "  <!-- Scanned files:"
		for _, f in ipairs(result.local_files) do
			lines[#lines + 1] = "       " .. relpath(result.dir, f)
		end
		lines[#lines + 1] = "  -->"
		lines[#lines + 1] = ""
	end

	if #result.orphans_unresolved > 0 then
		lines[#lines + 1] = "  <!-- Unresolved namespace-only imports (no matching local XSD):"
		for _, ns in ipairs(result.orphans_unresolved) do
			lines[#lines + 1] = "       " .. ns
		end
		lines[#lines + 1] = "  -->"
		lines[#lines + 1] = ""
	end

	lines[#lines + 1] = "</catalog>"
	lines[#lines + 1] = ""
	return table.concat(lines, "\n")
end

function M.generate(dir, opts)
	opts = opts or {}
	dir = abspath(dir or vim.fn.getcwd())
	local out_path = opts.path or (dir .. "/catalog.xml")
	local result = M.analyze(dir, { deep = opts.deep })
	local xml = M.render(result)

	if path_exists(out_path) and not opts.force then
		return false, "Catalog already exists: " .. out_path .. " (use :XmlCatalogGenerate! to overwrite)"
	end

	local f, err = io.open(out_path, "w")
	if not f then
		return false, "Cannot write " .. out_path .. ": " .. tostring(err)
	end
	f:write(xml)
	f:close()

	local n_sys, n_uri = 0, 0
	for _, e in ipairs(result.entries) do
		if e.kind == "system" then
			n_sys = n_sys + 1
		else
			n_uri = n_uri + 1
		end
	end

	local msg = string.format(
		"Wrote %s\n  %d local system mapping(s), %d namespace mapping(s), %d file(s) scanned",
		out_path,
		n_sys,
		n_uri,
		#(result.local_files or {})
	)
	if #result.warnings > 0 then
		msg = msg .. "\nNotes:\n  • " .. table.concat(result.warnings, "\n  • ")
	end
	if #result.orphans_unresolved > 0 then
		msg = msg .. "\nUnresolved namespaces:\n  • " .. table.concat(result.orphans_unresolved, "\n  • ")
	end
	return true, msg
end

function M.maybe_suggest(bufnr)
	bufnr = bufnr or 0
	local path = vim.api.nvim_buf_get_name(bufnr)
	if path == "" then
		return
	end
	local ft = vim.bo[bufnr].filetype
	if ft ~= "xml" and ft ~= "xsd" then
		return
	end
	local dir = vim.fs.dirname(path)
	if path_exists(dir .. "/catalog.xml") or path_exists(dir .. "/xml-catalog.xml") then
		return
	end
	local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	local has_orphan = false
	for tag in text:gmatch("<%s*[%w:]*import%s.->") do
		local ns = tag:match('namespace%s*=%s*"([^"]+)"')
		local loc = tag:match('schemaLocation%s*=%s*"([^"]+)"') or tag:match('location%s*=%s*"([^"]+)"')
		if ns and (not loc or loc == "") then
			has_orphan = true
			break
		end
	end
	-- Also suggest if folder has .xsd files but no catalog
	local has_xsd = false
	local fd = vim.uv.fs_scandir(dir)
	if fd then
		while true do
			local name = vim.uv.fs_scandir_next(fd)
			if not name then
				break
			end
			if name:lower():match("%.xsd$") then
				has_xsd = true
				break
			end
		end
	end
	if not has_orphan and not has_xsd then
		return
	end

	vim.schedule(function()
		vim.notify(
			"XML folder has schemas/imports but no catalog.xml.\n"
				.. "Run :XmlCatalogGenerate to index local XSD files for LemMinX.",
			vim.log.levels.INFO,
			{ title = "xml catalog" }
		)
	end)
end

return M
