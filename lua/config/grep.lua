-- Shared ripgrep helpers for snacks.picker.grep and classic :grepadd (ga).
--
-- Word greps auto-scope to the current buffer language when ripgrep recognizes it.
-- Override mismatches via vim.g.grep_ft_map; disable auto-scope with:
--   vim.g.grep_scope_filetype = false
--
-- Prompt (g/):  pattern -- -i -v -t go
-- ga:           :grepadd! -i -v -t ruby pattern

local M = {}

local rg_types ---@type table<string, boolean>?

---@return table<string, boolean>
local function load_rg_types()
	if rg_types then
		return rg_types
	end
	rg_types = {}
	if vim.fn.executable("rg") ~= 1 then
		return rg_types
	end
	for _, line in ipairs(vim.fn.systemlist({ "rg", "--type-list" })) do
		local t = line:match("^([^:]+):")
		if t then
			rg_types[t] = true
		end
	end
	return rg_types
end

-- Vim filetype → ripgrep -t when names differ (`rg --type-list`).
M.default_ft_map = {
	bash = "sh",
	csh = "sh",
	ksh = "sh",
	zsh = "sh",
	javascript = "js",
	javascriptreact = "js",
	typescript = "ts",
	typescriptreact = "ts",
	dockerfile = "docker",
	htmldjango = "html",
	less = "css",
	proto = "protobuf",
	sass = "css",
	scss = "css",
}

---@return table<string, string>
function M.ft_map()
	return vim.tbl_extend("force", M.default_ft_map, vim.g.grep_ft_map or {})
end

---@param vim_ft? string
---@return string?
function M.rg_ft(vim_ft)
	if not vim_ft or vim_ft == "" then
		return nil
	end

	local types = load_rg_types()
	local mapped = M.ft_map()[vim_ft]

	if types[vim_ft] then
		return vim_ft
	end
	if mapped and (not next(types) or types[mapped]) then
		return mapped
	end
	return nil
end

---@return string?
function M.buffer_ft()
	if vim.g.grep_scope_filetype == false then
		return nil
	end
	return M.rg_ft(vim.bo.filetype)
end

---@class config.grep.Flags
---@field insensitive? boolean force -i (rg default in picker is --smart-case)
---@field invert? boolean -v invert match
---@field ft? string|string[]|false ripgrep -t; false disables auto filetype
---@field use_ft? boolean default true for word greps

---@param opts snacks.picker.grep.Config
---@return snacks.picker.grep.Config
function M.opts(opts)
	opts = vim.deepcopy(opts or {})
	local args = opts.args or {}

	if opts.insensitive then
		args[#args + 1] = "-i"
	end
	if opts.invert then
		args[#args + 1] = "-v"
	end
	if #args > 0 then
		opts.args = args
	end

	local ft = opts.ft
	if ft == nil and opts.use_ft ~= false then
		ft = M.buffer_ft()
	elseif ft == false then
		ft = nil
	end
	opts.ft = ft

	opts.insensitive = nil
	opts.invert = nil
	opts.use_ft = nil

	return opts
end

---@param opts? snacks.picker.grep.Config
function M.picker(opts)
	return Snacks.picker.grep(M.opts(opts))
end

---@param whole boolean
---@param flags? config.grep.Flags
function M.word(whole, flags)
	flags = vim.deepcopy(flags or {})
	local word = vim.fn.expand("<cword>")
	if word == "" then
		return
	end
	if whole then
		flags.args = flags.args or {}
		table.insert(flags.args, "--word-regexp")
	end
	M.picker(vim.tbl_extend("force", flags, { search = word, regex = false }))
end

return M