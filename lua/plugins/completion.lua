-- Extend blink.cmp with additional completion sources.
--
-- LazyVim already configures:
--   default sources : lsp, path, snippets, buffer
--   cmdline         : enabled, shows on ':'
--   treesitter draw : LSP items are highlighted with treesitter syntax
--
-- We add:
--   omni   – vim's omnifunc (disabled when LSP omni is active, no duplicates)
--   spell  – dictionary / spell-checker words (ribru17/blink-cmp-spell)
--   tmux   – words from visible tmux panes  (mgalliou/blink-cmp-tmux)

return {
	{
		"saghen/blink.cmp",
		-- use a release tag to download pre-built binaries
		version = "1.*",
		-- AND/OR build from source
		-- build = 'cargo build --release',
		-- If you use nix, you can build from source with:
		-- build = 'nix run .#build-plugin',

		---@module 'blink.cmp'
		---@type blink.cmp.Config

		dependencies = {
			"ribru17/blink-cmp-spell",
			"mgalliou/blink-cmp-tmux",
			"L3MON4D3/LuaSnip",
		},

		opts = function(_, opts)
			-- Explicit ordered source list (replaces whatever LazyVim sets)
			opts.sources = opts.sources or {}
			opts.sources.default = { "lsp", "snippets", "path", "buffer", "omni", "spell", "tmux" }

			opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {

				lsp = {
					enabled = true,
					name = "LSP",
					module = "blink.cmp.sources.lsp",
					fallbacks = { "buffer" },
					opts = { tailwind_color_icon = "██" },
					async = false,
					timeout_ms = 2000,
					transform_items = nil,
					should_show_items = true,
					max_items = nil,
					min_keyword_length = 0,
					score_offset = 50,
					override = nil,
				},

				-- ── omni ──────────────────────────────────────────────────────────────
				-- Wraps vim's omnifunc. Disabled when LSP provides its own omnifunc
				-- so there's no duplication with the lsp source.
				omni = {
					name = "Omni",
					module = "blink.cmp.sources.complete_func",
					enabled = function()
						return vim.bo.omnifunc ~= "" and vim.bo.omnifunc ~= "v:lua.vim.lsp.omnifunc"
					end,
					score_offset = 1,
				},

				-- ── spell ─────────────────────────────────────────────────────────────
				-- Suggests words from vim's spell dictionary.
				-- Score is kept low so LSP/snippets appear first.
				spell = {
					name = "Spell",
					module = "blink-cmp-spell",
					score_offset = -3,
					enabled = function()
						return vim.wo.spell
					end,
				},

				-- ── tmux ──────────────────────────────────────────────────────────────
				-- Words from all visible tmux panes (great for CLI args, paths, etc.)
				-- Only active when nvim is running inside a tmux session.
				tmux = {
					name = "tmux",
					module = "blink-cmp-tmux",
					score_offset = -5,
					enabled = function()
						return vim.env.TMUX ~= nil
					end,
					opts = {
						all_panes = true,
						capture_history = true,
					},
					async = true,
				},

				path = {
					module = "blink.cmp.sources.path",
					score_offset = 4,
					fallbacks = { "buffer" },
					opts = {
						trailing_slash = true,
						label_trailing_slash = true,
						get_cwd = function(context)
							return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
						end,
						show_hidden_files_by_default = false,
						ignore_root_slash = false,
						max_entries = 10000,
					},
				},

				snippets = {
					module = "blink.cmp.sources.snippets",
					score_offset = 10,
					opts = {
						use_show_condition = true,
						show_autosnippets = true,
						prefer_doc_trig = false,
						use_label_description = true,
					},
				},

				buffer = {
					module = "blink.cmp.sources.buffer",
					score_offset = 2,
					opts = {
						get_bufnrs = function()
							return vim.iter(vim.api.nvim_list_wins())
								:map(function(win)
									return vim.api.nvim_win_get_buf(win)
								end)
								:filter(function(buf)
									return vim.bo[buf].buftype ~= "nofile"
								end)
								:totable()
						end,
						get_search_bufnrs = function()
							return { vim.api.nvim_get_current_buf() }
						end,
						max_sync_buffer_size = 20000,
						max_async_buffer_size = 200000,
						max_total_buffer_size = 500000,
						retention_order = { "focused", "visible", "recency", "largest" },
						use_cache = true,
						enable_in_ex_commands = false,
					},
				},

				lazydev = {
					enabled = false,
					module = "lazydev.integrations.blink",
					name = "LazyDev",
					score_offset = 0,
				},

				cmdline = {
					enabled = true,
					module = "blink.cmp.sources.cmdline",
					keymap = { preset = "cmdline" },
					sources = { "buffer", "cmdline" },
					completion = {
						ghost_text = { enabled = true },
						menu = {
							auto_show = function(ctx, _)
								return ctx.mode == "cmdwin"
							end,
						},
					},
				},
			})

			opts.appearance = {
				nerd_font_variant = "mono",
				highlight_ns = vim.api.nvim_create_namespace("blink_cmp"),
				use_nvim_cmp_as_default = true,
				kind_icons = {
					Text = "󰉿",
					Method = "",
					Function = "󰊕",
					Constructor = "󰒓",
					Field = "󰜢",
					Variable = "󰆦",
					Property = "󰖷",
					Class = "󱡠",
					Interface = "󱡠",
					Struct = "󱡠",
					Module = "󰅩",
					Unit = "󰪚",
					Value = "󰦨",
					Enum = "",
					EnumMember = "",
					Keyword = "󰻾",
					Constant = "󰏿",
					Snippet = "󱄽",
					Color = "󰏘",
					File = "󰈔",
					Reference = "󰬲",
					Folder = "󰉋",
					Event = "󱐋",
					Operator = "󰪚",
					TypeParameter = "󰬛",
				},
			}

			-- ── completion (UI / trigger / list / accept / documentation / ghost_text) ──
			opts.completion = {
				keyword = {
					-- 'prefix' will fuzzy match on the text before the cursor
					-- 'full' will fuzzy match on the text before _and_ after the cursor
					range = "prefix",
				},

				trigger = {
					prefetch_on_insert = true,
					show_on_backspace = true,
					show_on_backspace_in_keyword = true,
					show_on_backspace_after_accept = true,
					show_on_backspace_after_insert_enter = true,
					show_on_keyword = true,
					show_on_trigger_character = true,
					show_on_accept_on_trigger_character = true,
					show_on_insert_on_trigger_character = true,
					show_on_insert = true,
					show_on_blocked_trigger_characters = { " ", "\n", "\t" },
					show_on_x_blocked_trigger_characters = { "'", '"', "(" },
				},

				list = {
					max_items = 250,
					selection = {
						preselect = true,
						auto_insert = false,
					},
					cycle = {
						from_bottom = true,
						from_top = true,
					},
				},

				-- accept lives under completion, NOT under completion.list
				accept = {
					dot_repeat = true,
					create_undo_point = true,
					auto_brackets = {
						enabled = true,
						default_brackets = { "(", ")" },
						override_brackets_for_filetypes = {},
						kind_resolution = {
							enabled = true,
							blocked_filetypes = { "typescriptreact", "javascriptreact", "vue" },
						},
						semantic_token_resolution = {
							enabled = true,
							blocked_filetypes = { "java", "go", "c", "php" },
							timeout_ms = 400,
						},
					},
				},

				documentation = {
					auto_show = true,
					treesitter_highlighting = true,
					draw = function(args)
						args.default_implementation()
					end,
					window = {
						min_width = 10,
						max_width = 80,
						max_height = 20,
						border = nil,
						winblend = 0,
						winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
						scrollbar = true,
						direction_priority = {
							menu_north = { "e", "w", "n", "s" },
							menu_south = { "e", "w", "s", "n" },
						},
					},
				},

				ghost_text = {
					enabled = true,
					show_with_selection = true,
					show_without_selection = true,
					show_with_menu = true,
					show_without_menu = true,
				},
			}

			-- ── fuzzy is a TOP-LEVEL key, NOT nested under completion ──────────────────
			opts.fuzzy = {
				implementation = "prefer_rust_with_warning",

				max_typos = function(keyword)
					return math.floor(#keyword / 4)
				end,

				frecency = {
					enabled = true,
					path = vim.fn.stdpath("state") .. "/blink/cmp/frecency.dat",
					unsafe_no_lock = false,
				},

				use_proximity = true,

				sorts = {
					"exact",
					"score",
					"sort_text",
				},

				prebuilt_binaries = {
					download = true,
					ignore_version_mismatch = false,
					force_version = nil,
					force_system_triple = nil,
					extra_curl_args = {},
					proxy = {
						from_env = true,
						url = nil,
					},
				},
			}

			return opts
		end,
	},

	-- ── vim-dadbod-completion crash fix ───────────────────────────────────────
	-- The plugin's after/plugin file checks for the ancient completion.nvim API
	-- (`completion.addCompletionSource`) without verifying the method exists.
	-- Something in the loaded rtp provides a `completion` module that lacks this
	-- method, causing a crash on CmdlineEnter.
	-- Fix: inject a safe stub before the plugin loads so the call becomes a no-op.
	{
		"kristijanhusak/vim-dadbod-completion",
		init = function()
			if not package.loaded["completion"] then
				package.loaded["completion"] = {
					addCompletionSource = function() end, -- no-op stub
				}
			end
		end,
	},

	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		build = "make install_jsregexp",
	},
}
