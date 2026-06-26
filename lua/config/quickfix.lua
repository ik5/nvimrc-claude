-- Quickfix / location list navigation.
-- Used by classic :grep (ga, …). Keys match snacks.picker / neo-tree:
--   <CR>   open in the window that was active before the list
--   <C-x>  horizontal split
--   <C-v>  vertical split

local M = {}

---@param split? "split" | "vsplit"
function M.open_item(split)
	local info = vim.fn.getqflist({ idx = 0 })
	local item = info.items[info.idx]
	if not item or not item.filename or item.filename == "" then
		return
	end

	if not split then
		vim.cmd("cc")
		return
	end

	local fname = vim.fn.fnameescape(item.filename)
	vim.cmd("cclose")

	local win = require("config.window_picker").pick()
	if not win then
		return
	end
	vim.api.nvim_set_current_win(win)
	vim.cmd(string.format("%s %s", split, fname))

	if item.lnum and item.lnum > 0 then
		vim.api.nvim_win_set_cursor(0, { item.lnum, math.max((item.col or 1) - 1, 0) })
	end
	vim.cmd("normal! zv")
end

function M.setup_buffer(buf)
	local opts = { buffer = buf, silent = true }
	vim.keymap.set("n", "<CR>", function()
		M.open_item()
	end, vim.tbl_extend("force", opts, { desc = "Open in last window" }))
	vim.keymap.set("n", "<C-x>", function()
		M.open_item("split")
	end, vim.tbl_extend("force", opts, { desc = "Open in horizontal split" }))
	vim.keymap.set("n", "<C-v>", function()
		M.open_item("vsplit")
	end, vim.tbl_extend("force", opts, { desc = "Open in vertical split" }))
end

return M