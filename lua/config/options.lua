-- Re-assert backslash leader after LazyVim's options.lua overrides it to <Space>
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- ── Language server preferences ───────────────────────────────────────────────
-- Must be set before LazyVim extras are processed.
vim.g.lazyvim_python_lsp = "basedpyright" -- fork of pyright; stricter types
-- vim.g.lazyvim_php_lsp = "phpactor"     -- phpactor is already the default

-- Options that differ from LazyVim defaults.
-- LazyVim already sets: expandtab, shiftwidth=2, tabstop=2, smartindent,
-- Override indentation: 4-space soft tabs everywhere (Go uses hard tabs via autocmd)
-- splitbelow, splitright, termguicolors, cursorline, number, undofile,
-- ignorecase, smartcase, incsearch, hlsearch, and many others.

local opt = vim.opt

-- Indentation: 4-space soft tabs (override LazyVim's 2-space defaults)
opt.tabstop = 2 -- a <Tab> displays as 2 columns
opt.shiftwidth = 2 -- >> / << / autoindent step
opt.softtabstop = 2 -- <Tab> in insert mode inserts 2 spaces
-- expandtab is already true via LazyVim (spaces, not hard tabs)

-- Cmdline: must be >= 1 since noice.nvim is disabled
opt.cmdheight = 2

-- Line numbers: absolute only (LazyVim defaults to relativenumber = true)
opt.relativenumber = false
opt.numberwidth = 3

-- Mouse: disabled (LazyVim enables it by default)
opt.mouse = ""

-- Wrap: on (LazyVim defaults off)
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.breakindentopt = "shift:2"
opt.showbreak = "↳ "
-- Use number column for wrapped text continuation
vim.opt.cpoptions:append("n")

-- Text width and visual guide
opt.textwidth = 120
opt.colorcolumn = "120"

-- Scroll: keep 3 context lines (LazyVim uses 4)
opt.scrolloff = 3
opt.sidescrolloff = 8

-- Sign column: show up to 2 signs (LazyVim uses "yes" = always 1 wide)
opt.signcolumn = "yes:2"

-- Spell: add Hebrew alongside English
opt.spell = true
opt.spelllang = { "en_us", "en" }
opt.spellfile = "~/tmp/spell/en_us.utf8.add,~/tmp/spell/en.utf8.add"

-- Swap and undo directories (keep out of working dir)
opt.directory = vim.fn.expand("~/tmp/swp//")
opt.undodir = vim.fn.expand("~/tmp/vim_undo/")

-- :substitute preview in a split (LazyVim uses "nosplit")
opt.inccommand = "split"

-- Completion menu height (LazyVim uses 10)
opt.pumheight = 15

-- Ruler format: buf#, filetype, line/total, col, position, char value
opt.ruler = true
opt.rulerformat = "%60(%=%b/0x%B b:%n %y%m%r%w %l/%L->%c%V %P%)"

-- Show mode in cmd line (LazyVim hides it; lualine handles it, but we want it visible)
opt.showmode = false -- lualine shows the mode already

-- List chars: match original config
opt.listchars = { tab = "  ", trail = "·", extends = "›", precedes = "‹", nbsp = "␣" }

-- Split separators: heavy box-drawing chars so splits are clearly visible.
-- WinSeparator highlight in autocmds.lua adds colour on top.
opt.fillchars = {
  vert      = "┃", vertleft  = "┫", vertright = "┣", verthoriz = "╋",
  horiz     = "━", horizup   = "┻", horizdown = "┳",
}

-- Concealment: 1 instead of LazyVim's 2
opt.conceallevel = 1

-- Folding: no fold column
opt.foldcolumn = "0"

-- Match pairs: also match <>
opt.matchpairs:append("<:>")
opt.showmatch = true
opt.matchtime = 3

-- Cursor stays at column when moving between lines
opt.startofline = false

-- File and encoding
opt.encoding = "utf-8"
opt.fileformats = "unix,dos,mac"

-- Virtual edit: cursor beyond last char + block mode
opt.virtualedit = "onemore,block"

-- History size
opt.history = 10000

-- Security: no modelines
opt.modeline = false
opt.modelines = 0

-- Per-project config: load .nvim.lua from the project root when present.
-- Neovim 0.9+ uses a trust system (:trust / :trust! to approve a file once).
opt.exrc = true

-- Joinspaces: two spaces after sentence-ending punctuation
opt.joinspaces = true

-- Allow these keys to wrap to prev/next line
opt.whichwrap = "b,s,<,>"

-- Backspace: conventional behaviour
opt.backspace = "indent,eol,start"

-- Display: show last line, use message separator
opt.display = "lastline,msgsep"

-- Report changes for >= 1 line (Vim default is 2)
opt.report = 1

-- Session options
opt.sessionoptions = "blank,buffers,curdir,folds,help,options,resize,tabpages,winpos,winsize"

-- Switch buffer behaviour
opt.switchbuf = "uselast,useopen,split"

-- Tags
opt.tags = vim.fn.expand("~/tmp/tags") .. ",tags"

-- Window title
opt.title = true
opt.titleold = ""
opt.titlestring = " %F "

-- Wildmenu
opt.wildmenu = true
opt.wildmode = "list:longest,full"
opt.wildignore:append({
	".hg",
	".git",
	".svn",
	".cvn",
	"_build",
	"*.aux",
	"*.out",
	"*.toc",
	"*.jpg",
	"*.bmp",
	"*.gif",
	"*.png",
	"*.jpeg",
	"*.o",
	"*.obj",
	"*.exe",
	"*.dll",
	"*.manifest",
	"*.pyc",
	"*.spl",
	"*.sw?",
	"*.DS_Store",
	"*.rdb",
	"*.so",
	"*.zip",
	"*.db",
	"*.sqlite*",
	"vendor/*",
	"node_modules/*",
	".node_modules/*",
})

-- Diff options
opt.diffopt = "internal,filler,closeoff,iwhite"

-- Update time: 400 ms (LazyVim uses 200)
opt.updatetime = 400

-- Timeout: rely only on ttimeoutlen, not timeoutlen (matches original)
opt.timeout = false
opt.ttimeoutlen = 5

-- No lazyredraw (keep screen updating during macros etc.)
opt.lazyredraw = false

-- Number formats for Ctrl-A/X
opt.nrformats = "octal,hex,alpha,bin"

-- Search path: include cwd and subdirs
opt.path:append(".,**")

-- Clipboard: use the '*' register if available (matches original)
if vim.fn.has("clipboard") == 1 then
	opt.clipboard = "unnamed"
end
