-- Go-specific tools beyond what the LazyVim lang.go extra provides.
--
-- The Go extra already installs these binaries via Mason:
--   gomodifytags  – add / remove / clear struct field tags
--   impl          – generate method stubs for an interface
--
-- They were only wired via none-ls (which we don't use), so we expose
-- them here as simple keymaps registered only in Go buffers.
--
-- Keys (Go buffers only):
--   <leader>gta   add    struct tags   (prompts for tag names)
--   <leader>gto   add    tag options   (e.g. omitempty)
--   <leader>gtr   remove struct tags   (prompts for tag names)
--   <leader>gtx   clear  all tags on struct field
--   <leader>gI    generate interface stubs via impl

local function run(cmd)
  local out = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Go tool error:\n" .. out, vim.log.levels.ERROR, { title = "go tools" })
    return nil
  end
  return out
end

-- gomodifytags: update tags on the struct field under the cursor.
-- Uses byte offset so it works regardless of indentation / line counting.
local function modifytags(flag, prompt_label, default_val)
  local offset = vim.fn.line2byte(vim.fn.line(".")) + vim.fn.col(".") - 2
  local file   = vim.fn.expand("%:p")
  local value  = vim.fn.input(prompt_label, default_val or "")
  if value == "" then return end
  local out = run(string.format(
    "gomodifytags -file %s -offset %d -%s %s -format source -quiet",
    vim.fn.shellescape(file), offset, flag, vim.fn.shellescape(value)
  ))
  if not out then return end
  -- Replace buffer lines with the re-formatted source output
  local lines = vim.split(out, "\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.fn.winrestview(view)
end

local function cleartags()
  local offset = vim.fn.line2byte(vim.fn.line(".")) + vim.fn.col(".") - 2
  local file   = vim.fn.expand("%:p")
  local out = run(string.format(
    "gomodifytags -file %s -offset %d -clear-tags -format source -quiet",
    vim.fn.shellescape(file), offset
  ))
  if not out then return end
  local lines = vim.split(out, "\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.fn.winrestview(view)
end

-- impl: generate method stubs for an interface and insert below cursor.
local function goImpl()
  local recv = vim.fn.input("Receiver (e.g. r *MyType): ")
  if recv == "" then return end
  local iface = vim.fn.input("Interface (e.g. io.Reader): ")
  if iface == "" then return end
  local out = run(string.format("impl %s %s",
    vim.fn.shellescape(recv), vim.fn.shellescape(iface)))
  if not out then return end
  local lines = vim.split(out, "\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end
  local row = vim.fn.line(".")
  vim.api.nvim_buf_set_lines(0, row, row, false, lines)
end

return {
  {
    -- Attach keymaps only when editing a Go file
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "go",
        group = vim.api.nvim_create_augroup("go_tools_keymaps", { clear = true }),
        callback = function(ev)
          local map = function(lhs, fn, desc)
            vim.keymap.set("n", lhs, fn, { buffer = ev.buf, desc = desc, silent = true })
          end

          -- ── gomodifytags ────────────────────────────────────────────
          map("<leader>gta", function()
            modifytags("add-tags", "Tags to add (e.g. json,yaml): ", "json,yaml")
          end, "Go: Add struct tags")

          map("<leader>gto", function()
            modifytags("add-options", "Options to add (e.g. json=omitempty): ", "json=omitempty")
          end, "Go: Add tag options")

          map("<leader>gtr", function()
            modifytags("remove-tags", "Tags to remove (e.g. json,yaml): ", "")
          end, "Go: Remove struct tags")

          map("<leader>gtx", cleartags, "Go: Clear all struct tags")

          -- ── impl ─────────────────────────────────────────────────────
          map("<leader>gI", goImpl, "Go: Implement interface (impl)")
        end,
      })
      return opts
    end,
  },
}
