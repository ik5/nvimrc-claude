-- Formatter configuration via conform.nvim
--
-- LazyVim base already provides:
--   lua        → stylua
--   sh / bash  → shfmt
--   go         → goimports, gofumpt      (lang.go extra)
--   ruby       → rubocop / standardrb   (lang.ruby extra)
--   php        → php_cs_fixer           (lang.php extra)
--   sql        → sqlfluff               (lang.sql extra)
--   markdown   → prettier + markdownlint(lang.markdown extra)
--
-- LSP fallback (lsp_format = "fallback") handles:
--   rust       → rust-analyzer / rustfmt
--   yaml       → yamlls
--   json       → jsonls
--   toml       → taplo
--
-- This file adds what is missing:
--   python     → ruff_format   (ruff is already installed by lang.python extra)
--   JS/TS/HTML/CSS/SCSS/JSON/YAML → prettier  (explicit, overrides LSP fallback)
--   c / cpp    → clang_format  (explicit, clangd already provides the binary)
--   shfmt      → 4-space indent to match our global tabstop

return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- Python: ruff format (ruff handles both linting and formatting)
        python = { "ruff_format", "ruff_organize_imports" },

        -- Web: prettier is the community standard for all of these
        javascript      = { "prettier" },
        javascriptreact = { "prettier" },
        typescript      = { "prettier" },
        typescriptreact = { "prettier" },
        html            = { "prettier" },
        css             = { "prettier" },
        scss            = { "prettier" },
        less            = { "prettier" },
        json            = { "prettier" },
        jsonc           = { "prettier" },
        yaml            = { "prettier" },
        graphql         = { "prettier" },

        -- C / C++: explicit clang-format (binary ships with clangd)
        c   = { "clang_format" },
        cpp = { "clang_format" },
      },

      formatters = {
        -- shfmt: match our 4-space indent; -ci = indent switch cases
        shfmt = {
          prepend_args = { "-i", "4", "-ci" },
        },
        -- prettier: default tab width 4 when no project .prettierrc exists
        prettier = {
          prepend_args = { "--tab-width", "4" },
        },
      },
    },
  },

  -- Install prettier via Mason (everything else is already installed)
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "prettier" },
    },
  },
}
