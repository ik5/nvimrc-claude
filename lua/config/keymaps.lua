-- Keymaps ported from dotnvim/lua/base/keymapping.lua
-- Leader is '\' (set in init.lua before lazy loads)

local map = vim.keymap.set
local home = vim.fn.expand("~")

-- ─── Escape ───────────────────────────────────────────────────────────────────

map("i", "XX", "<Esc>")
map("c", "XX", "<C-c>")
map("o", "XX", "<Esc>")
map("v", "XX", "<Esc>gV")
map("n", "XX", "<Esc>:noh<CR>", { silent = true })
map("t", "XX", [[<C-\><C-n>]])

-- ─── Config reload ────────────────────────────────────────────────────────────

map("n", "<leader>R", ":source $MYVIMRC<CR>:filetype detect<CR>:echo 'init.lua reloaded'<CR>")

-- ─── Fast save ────────────────────────────────────────────────────────────────

map("n", "<leader>W", ":w!<CR>", { silent = true })

-- ─── Window navigation ────────────────────────────────────────────────────────
-- Note: LazyVim also maps <C-h/j/k/l> to the same window commands; these are identical.

map("n", "<C-J>", "<C-W>j")
map("n", "<C-K>", "<C-W>k")
map("n", "<C-H>", "<C-W>h")
map("n", "<C-L>", "<C-W>l")
map("n", "<C-Down>", "<C-W>j")
map("n", "<C-Up>", "<C-W>k")
map("n", "<C-Left>", "<C-W>h")
map("n", "<C-Right>", "<C-W>l")

map("i", "<C-J>", "<ESC><C-W>j")
map("i", "<C-K>", "<ESC><C-W>k")
map("i", "<C-H>", "<ESC><C-W>h")
map("i", "<C-L>", "<ESC><C-W>l")
map("i", "<C-Down>", "<ESC><C-W>j")
map("i", "<C-Up>", "<ESC><C-W>k")
map("i", "<C-Left>", "<ESC><C-W>h")
map("i", "<C-Right>", "<ESC><C-W>l")

-- Terminal window navigation
map("t", "<C-Down>", [[<C-\><C-n><C-W>j]])
map("t", "<C-Up>",   [[<C-\><C-n><C-W>k]])
map("t", "<C-Left>", [[<C-\><C-n><C-W>h]])
map("t", "<C-Right>",[[<C-\><C-n><C-W>l]])

-- Close all windows except the active one
-- NOTE: conflicts with LazyVim's <leader>q (quit/session). LazyVim's quit
-- group uses <leader>q + another key, so bare <leader>q should be fine,
-- but you may see a brief delay while Neovim waits for a second key.
map("n", "<leader>q", ":only<CR>", { silent = true })

-- Make <C-w> work in insert mode
map("i", "<C-W>", "<C-O><C-W>")

-- ─── Split resize ─────────────────────────────────────────────────────────────

map("n", "-", "<C-W>-")
map("n", "+", "<C-W>+")
map("n", "<M-,>", "<C-W>>")
map("n", "<M-.>", "<C-W><")

-- F2: delete the current buffer (keep window open via Snacks.bufdelete).
-- Only close the split afterwards when there are other editing windows left —
-- sidebars (neo-tree, aerial, undotree) are excluded from the count so that
-- closing the last editing split does not leave neo-tree alone (and exit nvim).
map("n", "<F2>", function()
  local sidebar_fts = { ["neo-tree"] = true, aerial = true, undotree = true }
  local editing_wins = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local ok, buf = pcall(vim.api.nvim_win_get_buf, win)
    if ok then
      local cfg = vim.api.nvim_win_get_config(win)
      local ft  = vim.bo[buf].filetype
      if cfg.relative == "" and not sidebar_fts[ft] then
        editing_wins = editing_wins + 1
      end
    end
  end
  Snacks.bufdelete()
  if editing_wins > 1 then
    vim.cmd("close")
  end
end, { silent = true, desc = "Close buffer (keep layout)" })

-- Equalize splits
map("n", "<Leader>=", "<C-w>=")

-- ─── Buffers ──────────────────────────────────────────────────────────────────
-- NOTE: <leader>d conflicts with LazyVim's debug <leader>d* group.
-- Debug plugins are not loaded in this minimal setup, so no actual conflict yet.

-- Snacks.bufdelete() deletes the buffer but keeps the window alive by
-- switching to another buffer (or a new empty one if none exist).
-- This prevents neo-tree from expanding when the last file is closed.
map("n", "<leader>d", function() Snacks.bufdelete() end, { silent = true, desc = "Delete buffer (keep window)" })
map("n", "<leader>D", function() Snacks.bufdelete({ wipeout = true }) end, { silent = true, desc = "Wipeout buffer (keep window)" })
map("n", "<M-d>", ":bn<CR>", { silent = true })
map("n", "<M-a>", ":bp<CR>", { silent = true })
map("n", "<leader>bfn", ":bn<CR>", { silent = true })
map("n", "<leader>bfp", ":bp<CR>", { silent = true })
map("n", "<Space>x", ":bn|bd #<CR>", { silent = true })

-- <C-b> prefix buffer management
map("n", "<C-b>b", "<C-^>", { silent = true })
map("n", "<C-b>p", ":bprevious<CR>", { silent = true })
map("n", "<C-b>n", ":bnext<CR>", { silent = true })

-- ─── Search ───────────────────────────────────────────────────────────────────

-- F5: toggle hlsearch
map("n", "<F5>", ":set hlsearch! hlsearch?<CR>")

-- n/N: centered search (LazyVim also does this; these are identical)
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Clear last search register
map("n", "<leader><F5>", ":let @/=''<CR>", { silent = true })

-- ─── Movement ─────────────────────────────────────────────────────────────────

-- Center on half-page scroll
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")

-- Treat wrapped lines as real lines when moving
map("n", "j", "gj")
map("n", "k", "gk")

-- Move lines with Alt-j/k
map("n", "<M-j>", "mz:m+<CR>`z", { silent = true })
map("n", "<M-k>", "mz:m-2<CR>`z", { silent = true })
map("v", "<M-j>", ":m'>+<CR>`<my`>mzgv`yo`z", { silent = true })
map("v", "<M-k>", ":m'<-2<CR>`>my`<mzgv`yo`z", { silent = true })

-- ─── Swap content ─────────────────────────────────────────────────────────────
-- NOTE: gc/gC were renamed to gx/gX to avoid conflict with LazyVim's gc=comment.

-- Swap current char with next / prev
map("n", "gx", "xph")
map("n", "gX", "Xph")

-- Swap current word with prev / next
map("n", "gl", [[<silent>"_yiw?\w\+\_W\+\%#<CR>:s/\(\%#\w\+\)\(\_W\+\)\(\w\+\)/\3\2\1/<CR><C-o><C-l>:nohlsearch<CR>]], { silent = true })
map("n", "gr", [[<silent>"_yiw:s/\(\%#\w\+\)\(\_W\+\)\(\w\+\)/\3\2\1/<CR><C-o>/\w\+\_W\+<CR><C-l>:nohlsearch<CR>]], { silent = true })

-- Swap current paragraph with next / prev
map("n", "g{", "{dap}p{")
map("n", "g}", "}dap{p}")

-- ─── VCS / Git ────────────────────────────────────────────────────────────────

-- Remove LazyVim's lazygit bindings (we use neogit instead)
pcall(vim.keymap.del, "n", "<leader>gg")
pcall(vim.keymap.del, "n", "<leader>gG")

-- Find merge conflict markers
map("n", "<leader>vcsfc", [[/\v^[<\|=>]{7}( .*\|$)<CR>]])

-- Exit diff mode
map("n", "<leader><C-w>", ":windo diffoff<CR>")

-- ─── Clipboard / yank ─────────────────────────────────────────────────────────

-- Paste and re-indent
map("n", "<leader>p", [[p`[v`]=]])
map("n", "<leader>P", [[P`[v`]=]])

-- Copy selection / line to ~/.vbuf (cross-instance clipboard)
map("v", "<leader>y", string.format(":w! %s/tmp/.vbuf<CR>", home))
map("n", "<leader>y", string.format(":.w! %s/tmp/.vbuf<CR>", home))
-- Paste from ~/.vbuf
map("n", "<leader>cf", string.format(":r %s/tmp/.vbuf<CR>", home))

-- Y: yank to end of line (LazyVim also maps this; identical)
map("n", "Y", "y$")

-- gp: visually reselect last yank
map("n", "gp", "`[v`]")

-- ─── Quickfix ─────────────────────────────────────────────────────────────────

-- q is disabled to prevent accidental macro recording; use Q instead
map("n", "q", "<Nop>")
-- Q records macros (replaces the old q key)
map("n", "Q", "q", { noremap = true })
-- M executes the q-register macro
map("n", "M", "@q")
map("v", "M", ":norm @q<CR>")

-- ─── Display toggles ──────────────────────────────────────────────────────────

-- Toggle hidden characters (listchars)
map("n", "<leader>hc", ":set list!<CR>")
map("i", "<leader>hc", "<ESC>:set list!<CR>a")

-- Toggle word wrap
map("n", "<leader>wrp", ":set wrap!<CR>")
map("i", "<leader>wrp", "<ESC>:set wrap!<CR>a")

-- Convert tabs to spaces
map("n", "<S-Tab>", ":retab<CR>")
map("i", "<S-Tab>", "<ESC>:retab<CR>i")
map("v", "<S-Tab>", ":retab<CR>")

-- Toggle relative line numbers
map("n", "<leader>rel", ":set rnu!<CR>")
map("i", "<leader>rel", "<ESC>:set rnu!<CR>a")

-- Toggle cursor indicators
map("n", "<leader>curc", ":set cursorcolumn!<CR>")
map("i", "<leader>curc", ":set cursorcolumn!<CR>")
map("n", "<leader>curr", ":set cursorline!<CR>")
map("i", "<leader>curr", ":set cursorline!<CR>")

-- ─── Editing helpers ──────────────────────────────────────────────────────────

-- Indent last changed text
map("n", "g=", "gV=")

-- Sort paragraph
map("n", "<leader>srt", "{V}k:!sort<CR>")
map("v", "<leader>srt", "{V}k:!sort<CR>")

-- Print full file path
map("n", "<C-f>", ":echo expand('%:p')<CR>")

-- ─── Find files (built-in) ────────────────────────────────────────────────────
-- Tip: once you add telescope, these become redundant.

map("n", ",f", ":find ")
map("n", ",s", ":sfind ")
map("n", ",v", ":vert sfind ")
map("n", ",t", ":tabfind ")

-- ─── Tabs ─────────────────────────────────────────────────────────────────────

map("n", "<C-PageDown>", "gt")
map("n", "<C-PageUp>", "gT")
map("n", "<C-O>", ":tabnew ")
map("n", "<C-T>", ":tabnew<CR>")

-- ─── Terminal ─────────────────────────────────────────────────────────────────

-- NOTE: <leader>T conflicts with LazyVim's <leader>t (tests/terminal) group.
-- No test runner is loaded in this minimal setup, so no actual conflict yet.
map("n", "<leader>T", ":terminal<CR>a")
map("t", "<leader><ESC>", [[<C-\><C-n>]])
map("t", "<A-[>", "<Esc>")

-- ─── Right-to-left (Hebrew / Arabic) ─────────────────────────────────────────

map("n", "<F9>", ":set invrl!<CR>")
map("i", "<F9>", "<Esc>:set invrl!<CR>a")
map("n", "<F8>", ":set invrevins!<CR>")
map("i", "<F8>", "<Esc>:set invrevins!<CR>a")

-- ─── Grep (ripgrep) ───────────────────────────────────────────────────────────

map("n", "gw", [[:silent grep! "\b<C-R><C-W>\b"<CR>:cw<CR>]])
map("n", "g/", [[:silent grep! ]])
map("n", "g*", [[:silent grep! -w <C-R><C-W> ]])
map("n", "ga", [[:silent grepadd! ]])

-- ─── LSP shortcuts ────────────────────────────────────────────────────────────
-- Open definition in a horizontal / vertical split.
-- (Plain `gd` uses snacks picker; inside the picker <C-s>=hsplit <C-v>=vsplit)

map("n", "<leader>gd", function()
  vim.cmd("split")
  vim.lsp.buf.definition()
end, { desc = "Go to Definition (hsplit)", silent = true })

map("n", "<leader>gD", function()
  vim.cmd("vsplit")
  vim.lsp.buf.definition()
end, { desc = "Go to Definition (vsplit)", silent = true })
