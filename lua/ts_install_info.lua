local M = {}

M.config = {
  width  = 42,
  height = 0.8,
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local function resolve(value, total)
  if value > 0 and value < 1 then
    return math.floor(total * value)
  end
  return math.floor(value)
end

local function get_grammars()
  local ok_ts, ts = pcall(require, "nvim-treesitter")
  if not ok_ts then
    vim.notify("nvim-treesitter not found", vim.log.levels.ERROR)
    return nil, nil
  end

  local available     = ts.get_available()
  local installed_list = ts.get_installed()

  local installed_set = {}
  for _, lang in ipairs(installed_list) do
    installed_set[lang] = true
  end

  table.sort(available)
  return available, installed_set
end

local function render_lines(available, installed_set, filter)
  local lines = {}
  local lang_index = {}

  for _, lang in ipairs(available) do
    local is_installed = installed_set[lang] == true
    if filter == "all"
      or (filter == "installed" and is_installed)
      or (filter == "missing" and not is_installed)
    then
      local icon = is_installed and "✓" or "✗"
      table.insert(lines, string.format(" %s  %s", icon, lang))
      lang_index[#lines] = { lang = lang, installed = is_installed }
    end
  end

  return lines, lang_index
end

local function apply_highlights(buf, shifted)
  local ns = vim.api.nvim_create_namespace("TSInstallInfoHL")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, entry in pairs(shifted) do
    local hl = entry.installed and "DiagnosticOk" or "DiagnosticError"
    vim.api.nvim_buf_add_highlight(buf, ns, hl, i - 1, 1, 4)
  end
  vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 0, 0, -1)
  vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 1, 0, -1)
end

function M.open()
  local available, initial_installed = get_grammars()
  if not available then return end

  local state = {
    installed_set = initial_installed,
    filter        = "all",
    au_id         = nil,
    timer         = nil,
  }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden  = "wipe"

  local width  = resolve(M.config.width, vim.o.columns)
  local height = math.min(#available + 6, resolve(M.config.height, vim.o.lines))
  local row    = math.floor((vim.o.lines   - height) / 2)
  local col    = math.floor((vim.o.columns - width)  / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative  = "editor",
    width     = width,
    height    = height,
    row       = row,
    col       = col,
    style     = "minimal",
    border    = "rounded",
    title     = " Treesitter grammars ",
    title_pos = "center",
  })

  vim.wo[win].cursorline = true
  vim.wo[win].wrap       = false

  local lang_index_ref = {}

  local function redraw()
    local lines, lang_index = render_lines(available, state.installed_set, state.filter)

    local n_installed, n_missing = 0, 0
    for _, lang in ipairs(available) do
      if state.installed_set[lang] then
        n_installed = n_installed + 1
      else
        n_missing = n_missing + 1
      end
    end

    local header = {
      string.format("  ✓ %d installed  ✗ %d missing  (showing %d)", n_installed, n_missing, #lines),
      "  [a]ll  [f]ilter installed  [m]issing  [i] install  [x] uninstall  [u] update  [q]uit",
      string.rep("─", width),
    }

    local all_lines = vim.list_extend(vim.deepcopy(header), lines)

    local cursor = vim.api.nvim_win_get_cursor(win)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, all_lines)
    vim.bo[buf].modifiable = false
    local line_count = vim.api.nvim_buf_line_count(buf)
    local row = math.max(1, math.min(cursor[1], line_count))
    vim.api.nvim_win_set_cursor(win, { row, cursor[2] })

    local offset  = #header
    local shifted = {}
    for lnum, entry in pairs(lang_index) do
      shifted[lnum + offset] = entry
    end
    lang_index_ref = shifted

    apply_highlights(buf, shifted)
  end

  local function current_entry()
    local lnum = vim.api.nvim_win_get_cursor(win)[1]
    return lang_index_ref[lnum]
  end

  local function stop_watching()
    if state.au_id then
      pcall(vim.api.nvim_del_autocmd, state.au_id)
      state.au_id = nil
    end
    if state.timer then
      pcall(function() state.timer:stop(); state.timer:close() end)
      state.timer = nil
    end
  end

  local function close_win()
    stop_watching()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- debounced refresh: waits 300ms after the LAST TSUpdate fires
  local function schedule_refresh()
    if state.timer then
      pcall(function() state.timer:stop(); state.timer:close() end)
      state.timer = nil
    end

    state.timer = vim.uv.new_timer()
    state.timer:start(300, 0, vim.schedule_wrap(function()
      if state.timer then
        pcall(function() state.timer:stop(); state.timer:close() end)
        state.timer = nil
      end
      if not vim.api.nvim_win_is_valid(win) then return end
      local _, new_installed = get_grammars()
      state.installed_set = new_installed
      redraw()
    end))
  end

  local function watch_for_update()
    if state.au_id then return end
    state.au_id = vim.api.nvim_create_autocmd("User", {
      pattern  = "TSUpdate",
      callback = function()
        if not vim.api.nvim_win_is_valid(win) then
          stop_watching()
          return
        end
        schedule_refresh()
      end,
    })
  end

  local function run_op(entry, cmd)
    watch_for_update()
    vim.cmd(cmd .. " " .. entry.lang)
  end

  redraw()

  local opts = { buffer = buf, nowait = true, silent = true }

  vim.keymap.set("n", "q",     close_win, opts)
  vim.keymap.set("n", "<Esc>", close_win, opts)

  vim.keymap.set("n", "a", function() state.filter = "all";       redraw() end, opts)
  vim.keymap.set("n", "f", function() state.filter = "installed"; redraw() end, opts)
  vim.keymap.set("n", "m", function() state.filter = "missing";   redraw() end, opts)

  vim.keymap.set("n", "i", function()
    local entry = current_entry()
    if not entry then return end
    if entry.installed then
      vim.notify(entry.lang .. " is already installed", vim.log.levels.INFO)
      return
    end
    run_op(entry, "TSInstall")
  end, opts)

  vim.keymap.set("n", "<CR>", function()
    local entry = current_entry()
    if not entry then return end
    if entry.installed then
      vim.notify(entry.lang .. " is already installed", vim.log.levels.INFO)
    else
      run_op(entry, "TSInstall")
    end
  end, opts)

  vim.keymap.set("n", "x", function()
    local entry = current_entry()
    if not entry then return end
    if not entry.installed then
      vim.notify(entry.lang .. " is not installed", vim.log.levels.INFO)
      return
    end
    run_op(entry, "TSUninstall")
  end, opts)

  vim.keymap.set("n", "u", function()
    local entry = current_entry()
    if not entry then return end
    if not entry.installed then
      vim.notify(entry.lang .. " is not installed", vim.log.levels.INFO)
      return
    end
    run_op(entry, "TSUpdate")
  end, opts)
end

vim.api.nvim_create_user_command("TSInstallInfo", function()
  M.open()
end, {})

return M
