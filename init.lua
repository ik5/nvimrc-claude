-- Leader must be set before lazy.nvim loads so all mappings use the right key
vim.g.mapleader = "\\"
vim.g.maplocalleader = "\\"

-- Disable netrw before any plugin loads so neo-tree handles directory navigation
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

-- Bootstrap lazy.nvim, LazyVim and plugins
require("config.lazy")
