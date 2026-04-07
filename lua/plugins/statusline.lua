-- Lualine extensions.
--
-- LazyVim's default right-side layout:
--   lualine_x: profiler | noice | dap | lazy-updates | diff
--   lualine_y: progress (%) | location (line:col)
--   lualine_z: clock
-- LazyVim's aerial extra already appends to lualine_c:
--   root-dir | diagnostics | filetype-icon | path | aerial (LSP symbols)
--
-- This file:
--   1. Appends to lualine_c:  block_context — innermost if/for/while block
--      (treesitter-level; aerial/LSP only shows function/class symbols)
--   2. Appends to lualine_x:  char value · EOL type · filetype text
--   3. Replaces lualine_z:    time + day-of-week + date

return {
	{
		"nvim-lualine/lualine.nvim",
		opts = function(_, opts)
			opts.sections = opts.sections or {}
			opts.sections.lualine_c = opts.sections.lualine_c or {}
			opts.sections.lualine_x = opts.sections.lualine_x or {}

			opts.icons_enabled = true
			opts.theme = "auto"

			-- ── Block context (treesitter) ────────────────────────────────────────
			-- Aerial/LSP in lualine_c shows function/class symbols.
			-- This component appends the innermost control-flow block the cursor
			-- sits in (if / for / while / repeat / do) using the built-in
			-- vim.treesitter API — no extra plugin required.
			local block_context = {
				function()
					local bufnr = vim.api.nvim_get_current_buf()
					local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
					if not ok or not parser then
						return ""
					end
					local trees = parser:parse()
					if not trees or not trees[1] then
						return ""
					end

					local cursor = vim.api.nvim_win_get_cursor(0)
					local row, col = cursor[1] - 1, cursor[2]
					local node = trees[1]:root():named_descendant_for_range(row, col, row, col)
					if not node then
						return ""
					end

					local block_types = {
						if_statement = true,
						for_statement = true,
						while_statement = true,
						repeat_statement = true,
						do_statement = true,
					}

					-- Walk up the tree to find the innermost enclosing block
					local current = node:parent()
					while current do
						if block_types[current:type()] then
							local start_row = current:start()
							local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)
							if lines[1] then
								local preview = vim.trim(lines[1])
								-- Strip trailing "then" / "do" keywords and trim again
								preview = preview:gsub("%s*then%s*$", ""):gsub("%s*do%s*$", "")
								return preview:sub(1, 60)
							end
						end
						current = current:parent()
					end
					return ""
				end,
				cond = function()
					-- Only show in normal buffers with a treesitter parser
					return vim.bo.buftype == "" and pcall(vim.treesitter.get_parser, vim.api.nvim_get_current_buf())
				end,
				color = { fg = "#8b9798" }, -- dimmed — subordinate to aerial symbols
			}

			table.insert(opts.sections.lualine_c, block_context)

			-- ── Character value under cursor ─────────────────────────────────────
			-- ASCII range: "65/0x41"   Unicode: "U+03B1"
			local char_val = {
				function()
					local line = vim.api.nvim_get_current_line()
					local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 0-indexed → 1-indexed
					local char = line:sub(col, col)
					if char == "" then
						return ""
					end
					local cp = vim.fn.char2nr(char)
					return string.format("%d/0x%02X", cp, cp)
				end,
				desc = "Character value under cursor",
			}

			-- ── EOL type ─────────────────────────────────────────────────────────
			local eol = { "fileformat", icons_enabled = true }

			-- ── Filetype text ─────────────────────────────────────────────────────
			-- Icon-only filetype is already in lualine_c; this adds the name
			local ft = { "filetype", icons_enabled = true }

			table.insert(opts.sections.lualine_x, char_val)
			table.insert(opts.sections.lualine_x, eol)
			table.insert(opts.sections.lualine_x, ft)

			-- ── Clock: time + day-of-week + date ─────────────────────────────────
			-- Replaces LazyVim's plain "%R" with "HH:MM  Sun 05/04/2026"
			opts.sections.lualine_z = {
				function()
					return "⌚" .. os.date("%R %a %d/%m/%Y📅")
				end,
			}

			return opts
		end,
	},
}
