-- Thin wrapper around nvim-window-picker.
-- All hint/filter settings live in lua/plugins/window-picker.lua (setup()).

local M = {}

local function valid_win(win)
	return type(win) == "number" and win > 0 and vim.api.nvim_win_is_valid(win)
end

local function set_win(win)
	if valid_win(win) then
		vim.api.nvim_set_current_win(win)
		return true
	end
	return false
end

---@param opts? table optional per-call overrides (avoid overriding `hint`)
---@return number|nil winid
function M.pick(opts)
	local wp = require("window-picker")
	if opts and next(opts) ~= nil then
		return wp.pick_window(opts)
	end
	return wp.pick_window()
end

--- Open snacks.picker result in a window chosen via window-picker.
---@param picker snacks.Picker
---@param split? "split" | "vsplit"
function M.snacks_open(picker, split)
	if vim.fn.mode():sub(1, 1) == "i" then
		vim.cmd.stopinsert()
		vim.schedule(function()
			M.snacks_open(picker, split)
		end)
		return
	end

	local items = picker:selected({ fallback = true })
	if #items == 0 then
		return
	end

	-- Hide (don't close) the picker while choosing a window.
	-- picker:close() schedules layout teardown and can invalidate win ids mid-pick.
	local hidden = false
	if not picker.closed and not picker.layout.split then
		picker.layout:hide()
		hidden = true
	end

	local target = M.pick()
	if not valid_win(target) then
		if hidden and not picker.closed then
			picker.layout:unhide()
		end
		return
	end

	if not picker.closed then
		picker:close()
	end

	if not set_win(target) then
		return
	end

	local item = items[1]
	local util = require("snacks.picker.util")
	local path = util.path(item)
	local buf = item.buf
	if not buf and path then
		buf = vim.fn.bufadd(path)
	end
	if not buf then
		return
	end
	vim.bo[buf].buflisted = true

	if split == "split" then
		vim.cmd("split")
	elseif split == "vsplit" then
		vim.cmd("vsplit")
	end

	vim.cmd("buffer " .. buf)

	local pos = item.pos
	if picker.opts and picker.opts.jump and picker.opts.jump.match and picker.matcher then
		pos = picker.matcher:bufpos(buf, item) or pos
	end
	if pos and pos[1] > 0 then
		pcall(vim.api.nvim_win_set_cursor, 0, { pos[1], pos[2] })
	end
	vim.cmd("norm! zv")
end

return M