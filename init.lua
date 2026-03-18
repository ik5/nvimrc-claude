-- Leader must be set before lazy.nvim loads so all mappings use the right key
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Disable netrw before any plugin loads so neo-tree handles directory navigation
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.cmd("set runtimepath+=" .. vim.env.HOME .. "/.local/share/nvim/site/")

-- Bootstrap lazy.nvim, LazyVim and plugins
require("config.lazy")

local ts_info = require("ts_install_info")
ts_info.setup({
	width = 90,
	height = 0.6,
})
