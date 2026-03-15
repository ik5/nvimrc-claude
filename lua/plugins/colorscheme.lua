return {
  {
    "loctvl842/monokai-pro.nvim",
    lazy = false,
    priority = 1000, -- load before everything else
    opts = {
      filter = "pro",
    },
  },

  -- Tell LazyVim to use this colorscheme instead of tokyonight
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "monokai-pro",
    },
  },
}
