-- Autocmds ported from dotnvim

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- ─── File position restore ────────────────────────────────────────────────────
-- Re-open files at the last cursor position

autocmd("BufReadPost", {
	group = augroup("restore_pos", { clear = true }),
	pattern = "*",
	callback = function()
		local line = vim.fn.line("'\"")
		if line > 1 and line <= vim.fn.line("$") then
			vim.cmd([[normal! g'"]])
		end
	end,
})

-- ─── Split equalization ───────────────────────────────────────────────────────

autocmd("VimResized", {
	group = augroup("equalize_splits", { clear = true }),
	pattern = "*",
	callback = function()
		vim.cmd("wincmd =")
	end,
})

-- ─── Auto-reload on focus / buffer enter ─────────────────────────────────────

autocmd({ "FocusGained", "BufEnter" }, {
	group = augroup("auto_reload", { clear = true }),
	pattern = "*",
	callback = function()
		vim.cmd("checktime")
	end,
})

-- ─── Terminal options ─────────────────────────────────────────────────────────

autocmd("TermOpen", {
	group = augroup("term_opts", { clear = true }),
	pattern = "*",
	callback = function()
		vim.wo.list = true
		vim.wo.wrap = true
	end,
})

-- ─── Quickfix auto-open ───────────────────────────────────────────────────────
-- Open quickfix/location list after grep commands

autocmd("QuickFixCmdPost", {
	group = augroup("auto_quickfix", { clear = true }),
	pattern = "[^l]*",
	callback = function()
		vim.cmd("cwindow")
	end,
})

autocmd("QuickFixCmdPost", {
	group = augroup("auto_loclist", { clear = true }),
	pattern = "l*",
	callback = function()
		vim.cmd("lwindow")
	end,
})

-- ─── Remap LazyVim quit group: \q* → \Q* ─────────────────────────────────────
-- Our \q = :only (close other windows). LazyVim's core keymaps include \qq
-- (quit all) and \qa (quit all no save). We move those to \Qq / \Qa.
-- Must run after VeryLazy so LazyVim's mappings already exist to be deleted.

autocmd("User", {
	group = augroup("remap_lazyvim_quit", { clear = true }),
	pattern = "VeryLazy",
	once = true,
	callback = function()
		local del = vim.keymap.del
		local map = vim.keymap.set

		local remaps = {
			{ "n", "<leader>qq", "<cmd>qa<cr>", "<leader>Qq", "Quit All" },
			{ "n", "<leader>qa", "<cmd>qa!<cr>", "<leader>Qa", "Quit All (force)" },
		}

		for _, r in ipairs(remaps) do
			pcall(del, r[1], r[2])
			map(r[1], r[4], r[3], { desc = r[5], silent = true })
		end
	end,
})

-- ─── :Diag* commands ─────────────────────────────────────────────────────────
-- Expose vim.diagnostic operations as commands (mirrors the ]d/[d keymaps).

local function diag_jump(next, severity)
	vim.diagnostic.jump({
		count = next and 1 or -1,
		severity = severity and vim.diagnostic.severity[severity] or nil,
	})
	vim.schedule(function()
		vim.diagnostic.open_float({ scope = "cursor", source = true, border = "rounded" })
	end)
end

vim.api.nvim_create_user_command("DiagNext", function()
	diag_jump(true)
end, { desc = "Next diagnostic" })
vim.api.nvim_create_user_command("DiagPrev", function()
	diag_jump(false)
end, { desc = "Prev diagnostic" })
vim.api.nvim_create_user_command("DiagNextError", function()
	diag_jump(true, "ERROR")
end, { desc = "Next error" })
vim.api.nvim_create_user_command("DiagPrevError", function()
	diag_jump(false, "ERROR")
end, { desc = "Prev error" })
vim.api.nvim_create_user_command("DiagNextWarn", function()
	diag_jump(true, "WARN")
end, { desc = "Next warning" })
vim.api.nvim_create_user_command("DiagPrevWarn", function()
	diag_jump(false, "WARN")
end, { desc = "Prev warning" })
vim.api.nvim_create_user_command("DiagInfo", function()
	vim.diagnostic.open_float({ scope = "cursor", source = true, border = "rounded" })
end, { desc = "Diagnostic detail at cursor (source + code)" })
vim.api.nvim_create_user_command("DiagLine", vim.diagnostic.open_float, { desc = "Line diagnostics (float)" })
vim.api.nvim_create_user_command("DiagList", function()
	vim.cmd("Trouble diagnostics toggle")
end, { desc = "All diagnostics (Trouble)" })
vim.api.nvim_create_user_command("DiagBufList", function()
	vim.cmd("Trouble diagnostics toggle filter.buf=0")
end, { desc = "Buffer diagnostics (Trouble)" })

-- ─── :Messages command ────────────────────────────────────────────────────────
-- Shows the snacks.nvim notification history (vim.notify calls from plugins).
-- These don't appear in the built-in :messages, so this fills that gap.

vim.api.nvim_create_user_command("Messages", function()
	Snacks.notifier.show_history()
end, { desc = "Show notification history (plugin errors, warnings, info)" })

-- ─── ripgrep setup ────────────────────────────────────────────────────────────

if vim.fn.executable("rg") == 1 then
	vim.o.grepprg = [[rg --hidden --glob "!.git" --no-heading --smart-case --vimgrep --follow $*]]
	vim.o.grepformat = "%f:%l:%c:%m,%f:%l:%m"
end

-- ─── Trailing whitespace: highlight + trim on save ───────────────────────────
-- Highlight trailing spaces (including lines that are only whitespace) with a
-- distinct background. Hidden in insert mode so typing isn't distracting.
-- On save, trailing whitespace is stripped and cursor position is restored.

vim.api.nvim_set_hl(0, "TrailingWhitespace", { bg = "#5c2020" })
-- Re-apply after colorscheme changes (which reset all highlights)
autocmd("ColorScheme", {
	group = augroup("trailing_ws_hl", { clear = true }),
	callback = function()
		vim.api.nvim_set_hl(0, "TrailingWhitespace", { bg = "#5c2020" })
	end,
})

local function trailing_match_add()
	if vim.bo.buftype ~= "" then
		return
	end
	if vim.w._trail_match then
		pcall(vim.fn.matchdelete, vim.w._trail_match)
	end
	vim.w._trail_match = vim.fn.matchadd("TrailingWhitespace", [[\s\+$]])
end

autocmd({ "BufWinEnter", "InsertEnter", "InsertLeave", "ModeChanged" }, {
	group = augroup("trailing_ws_show", { clear = true }),
	callback = trailing_match_add,
})

autocmd("BufWritePre", {
	group = augroup("trim_trailing_ws", { clear = true }),
	callback = function()
		if vim.bo.binary or vim.bo.filetype == "diff" then
			return
		end
		local pos = vim.api.nvim_win_get_cursor(0)
		vim.cmd([[keeppatterns %s/\s\+$//e]])
		vim.api.nvim_win_set_cursor(0, pos)
	end,
})

-- ─── Go: hard tabs ────────────────────────────────────────────────────────────
-- gofmt (and the Go community) mandates real tab characters for indentation.
-- Override the global 4-space-soft-tab default for Go buffers only.

autocmd("FileType", {
	group = augroup("go_tabs", { clear = true }),
	pattern = "go",
	callback = function()
		vim.bo.expandtab = false -- use real tab characters
		vim.bo.tabstop = 4
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 0 -- 0 = follow tabstop exactly (no mixed tabs/spaces)
	end,
})

-- ─── Terminal splits ──────────────────────────────────────────────────────────

vim.api.nvim_create_user_command("Term", function()
  vim.cmd("split")
  vim.cmd("terminal")
  vim.cmd("startinsert")
end, { desc = "Open terminal in horizontal split" })

vim.api.nvim_create_user_command("VTerm", function()
  vim.cmd("vsplit")
  vim.cmd("terminal")
  vim.cmd("startinsert")
end, { desc = "Open terminal in vertical split" })

-- ─── Format commands ──────────────────────────────────────────────────────────

-- FormatJSON: pretty-print selected/whole-buffer JSON via jq
vim.api.nvim_create_user_command("FormatJSON", function(args)
  vim.cmd(args.line1 .. "," .. args.line2 .. "!jq .")
end, { range = "%", desc = "Pretty-print JSON (jq)" })

-- FormatXML: pretty-print selected/whole-buffer XML via xmllint
vim.api.nvim_create_user_command("FormatXML", function(args)
  vim.cmd(args.line1 .. "," .. args.line2 .. "!xmllint --format --pretty 1 -")
end, { range = "%", desc = "Pretty-print XML (xmllint)" })

-- ─── ReloadFile ───────────────────────────────────────────────────────────────
-- :ReloadFile          – reload current buffer from disk, keep cursor
-- :ReloadFile a.go b.go – reload those buffers if open, keep each cursor

vim.api.nvim_create_user_command("ReloadFile", function(args)
  local function reload_buf(bufnr)
    local winid = vim.fn.bufwinid(bufnr) -- first window showing this buffer (-1 if hidden)
    local pos   = winid ~= -1 and vim.api.nvim_win_get_cursor(winid) or nil
    vim.api.nvim_buf_call(bufnr, function() vim.cmd("edit") end)
    if pos then pcall(vim.api.nvim_win_set_cursor, winid, pos) end
  end

  if #args.fargs == 0 then
    reload_buf(vim.api.nvim_get_current_buf())
  else
    for _, fname in ipairs(args.fargs) do
      local bufnr = vim.fn.bufnr(vim.fn.expand(fname))
      if bufnr == -1 then
        vim.notify("ReloadFile: no open buffer for " .. fname, vim.log.levels.WARN)
      else
        reload_buf(bufnr)
      end
    end
  end
end, { nargs = "*", complete = "buffer", desc = "Reload buffer(s) from disk, keep cursor position" })

-- ─── GenerateUUID ─────────────────────────────────────────────────────────────
-- Inserts a new UUIDv4 at the cursor position.

vim.api.nvim_create_user_command("GenerateUUID", function()
  local uuid = vim.fn.system("uuidgen"):gsub("%s+", ""):lower()
  vim.api.nvim_put({ uuid }, "c", true, true)
end, { desc = "Insert UUIDv4 at cursor (uuidgen)" })
