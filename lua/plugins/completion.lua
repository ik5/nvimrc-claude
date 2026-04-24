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
			-- Append extra sources to whatever LazyVim already sets
			opts.sources = opts.sources or {}
			opts.sources.default = opts.sources.default or { "lsp", "path", "snippets", "buffer" }
			vim.list_extend(opts.sources.default, { "omni", "spell", "tmux", "cmdline", "buffer" })

			opts.sources.providers = vim.tbl_deep_extend("force", opts.sources.providers or {}, {

				lsp = {
					enabled = true, -- Whether or not to enable the provider
					name = "LSP",
					module = "blink.cmp.sources.lsp",
					-- You may enable the buffer source, when LSP is available, by setting this to `{}`
					-- You may want to set the score_offset of the buffer source to a lower value, such as -5 in this case
					fallbacks = { "buffer" },
					opts = { tailwind_color_icon = "██" },

					--- These properties apply to !!ALL sources!!
					--- NOTE: All of these options may be functions to get dynamic behavior
					--- See the type definitions for more information
					async = false, -- Whether we should show the completions before this provider returns, without waiting for it
					timeout_ms = 2000, -- How long to wait for the provider to return before showing completions and treating it as asynchronous
					transform_items = nil, -- Function to transform the items before they're returned
					should_show_items = true, -- Whether or not to show the items
					max_items = nil, -- Maximum number of items to display in the menu
					-- Minimum number of characters in the keyword to trigger the provider
					-- May also be a function(ctx: blink.cmp.Context): number
					-- To ignore this property when manually showing the menu, set it like:
					-- min_keyword_length = function(ctx) return ctx.trigger.initial_kind == 'manual' and 0 or 1 end
					min_keyword_length = 0,
					-- If this provider returns 0 items, it will fallback to these providers.
					-- If multiple providers fallback to the same provider, all of the providers must return 0 items for it to fallback
					score_offset = 0, -- Boost/penalize the score of the items
					override = nil, -- Override the source's functions
				},

				-- ── omni ────────────────────────────────────────────────────────────
				-- Wraps vim's omnifunc. Disabled when LSP provides its own omnifunc
				-- so there's no duplication with the lsp source.
				omni = {
					name = "Omni",
					module = "blink.cmp.sources.complete_func",
					enabled = function()
						return vim.bo.omnifunc ~= "" and vim.bo.omnifunc ~= "v:lua.vim.lsp.omnifunc"
					end,
					score_offset = -2,
				},

				-- ── spell ────────────────────────────────────────────────────────────
				-- Suggests words from vim's spell dictionary.
				-- Score is kept low so LSP/snippets appear first.
				spell = {
					name = "Spell",
					module = "blink-cmp-spell",
					score_offset = -5,
					-- Only show spell suggestions when spell is actually on
					enabled = function()
						return vim.wo.spell
					end,
				},

				-- ── tmux ─────────────────────────────────────────────────────────────
				-- Words from all visible tmux panes (great for CLI args, paths, etc.)
				-- Only active when nvim is running inside a tmux session.
				tmux = {
					name = "tmux",
					module = "blink-cmp-tmux",
					score_offset = -6,
					enabled = function()
						return vim.env.TMUX ~= nil
					end,
					opts = {
						all_panes = true, -- include panes beyond the current one
						capture_history = true, -- also scan scrollback
					},
					async = true, -- don't block completion while tmux responds
				},

				path = {
					module = "blink.cmp.sources.path",
					score_offset = 3,
					fallbacks = { "buffer" },
					opts = {
						trailing_slash = true,
						label_trailing_slash = true,
						get_cwd = function(context)
							return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
						end,
						show_hidden_files_by_default = false,
						-- Treat `/path` as starting from the current working directory (cwd) instead of the root of your filesystem
						ignore_root_slash = false,
						-- Maximum number of files/directories to return. This limits memory use and responsiveness for very large folders.
						max_entries = 10000,
					},
				},

				snippets = {
					module = "blink.cmp.sources.snippets",
					score_offset = -1, -- receives a -3 from top level snippets.score_offset

					-- For `snippets.preset == 'luasnip'`
					opts = {
						-- Whether to use show_condition for filtering snippets
						use_show_condition = true,
						-- Whether to show autosnippets in the completion list
						show_autosnippets = true,
						-- Whether to prefer docTrig placeholders over trig when expanding regTrig snippets
						prefer_doc_trig = false,
						-- Whether to put the snippet description in the label description
						use_label_description = true,
					},
				},

				buffer = {
					module = "blink.cmp.sources.buffer",
					score_offset = -3,
					opts = {
						-- default to all visible buffers
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
						-- buffers when searching with `/` or `?`
						get_search_bufnrs = function()
							return { vim.api.nvim_get_current_buf() }
						end,
						-- Maximum total number of characters (in an individual buffer) for which buffer completion runs synchronously. Above this, asynchronous processing is used.
						max_sync_buffer_size = 20000,
						-- Maximum total number of characters (in an individual buffer) for which buffer completion runs asynchronously. Above this, the buffer will be skipped.
						max_async_buffer_size = 200000,
						-- Maximum text size across all buffers (default: 500KB)
						max_total_buffer_size = 500000,
						-- Order in which buffers are retained for completion, up to the max total size limit (see above)
						retention_order = { "focused", "visible", "recency", "largest" },
						-- Cache words for each buffer which increases memory usage but drastically reduces cpu usage. Memory usage depends on the size of the buffers from `get_bufnrs`. For 100k items, it will use ~20MBs of memory. Invalidated and refreshed whenever the buffer content is modified.
						use_cache = true,
						-- Whether to enable buffer source in substitute (:s), global (:g) and grep commands (:grep, :vimgrep, etc.).
						-- Note: Enabling this option will temporarily disable Neovim's 'inccommand' feature
						-- while editing Ex commands, due to a known redraw issue (see neovim/neovim#9783).
						-- This means you will lose live substitution previews when using :s, :smagic, or :snomagic
						-- while buffer completions are active.
						enable_in_ex_commands = false,
					},
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
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",

				highlight_ns = vim.api.nvim_create_namespace("blink_cmp"),

				-- Sets the fallback highlight groups to nvim-cmp's highlight groups
				-- Useful for when your theme doesn't support blink.cmp
				-- Will be removed in a future release
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

			opts.completions = {
				keyword = {
					-- 'prefix' will fuzzy match on the text before the cursor
					-- 'full' will fuzzy match on the text before _and_ after the cursor
					-- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
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

					-- LSPs can indicate when to show the completion window via trigger characters
					-- however, some LSPs (e.g. tsserver) return characters that would essentially
					-- always show the window. We block these by default.
					show_on_blocked_trigger_characters = { " ", "\n", "\t" },
					-- You can also block per filetype with a function:
					-- show_on_blocked_trigger_characters = function(ctx)
					--   if vim.bo.filetype == 'markdown' then return { ' ', '\n', '\t', '.', '/', '(', '[' } end
					--   return { ' ', '\n', '\t' }
					-- end,

					-- List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger
					-- the completion window when the cursor comes after a trigger character when
					-- entering insert mode/accepting an item
					show_on_x_blocked_trigger_characters = { "'", '"', "(" },
					-- or a function, similar to show_on_blocked_trigger_character
				},

				list = {
					-- Maximum number of items to display
					max_items = 250,

					selection = {
						-- When `true`, will automatically select the first item in the completion list
						preselect = true,

						-- When `true`, inserts the completion item automatically when selecting it
						-- You may want to bind a key to the `cancel` command (default <C-e>) when using this option,
						-- which will both undo the selection and hide the completion menu
						auto_insert = false,

						-- auto_insert = function(ctx) return vim.bo.filetype ~= 'markdown' end
					},

					cycle = {
						-- When `true`, calling `select_next` at the _bottom_ of the completion list
						-- will select the _first_ completion item.
						from_bottom = true,

						-- When `true`, calling `select_prev` at the _top_ of the completion list
						-- will select the _last_ completion item.
						from_top = true,
					},

					accept = {
						dot_repeat = true,
						create_undo_point = true,
						auto_brackets = {
							-- Whether to auto-insert brackets for functions
							enabled = true,
							-- Default brackets to use for unknown languages
							default_brackets = { "(", ")" },
							-- Overrides the default blocked filetypes
							-- See: https://github.com/Saghen/blink.cmp/blob/main/lua/blink/cmp/completion/brackets/config.lua#L5-L9
							override_brackets_for_filetypes = {},
							-- Synchronously use the kind of the item to determine if brackets should be added
							kind_resolution = {
								enabled = true,
								blocked_filetypes = { "typescriptreact", "javascriptreact", "vue" },
							},
							-- Asynchronously use semantic token to determine if brackets should be added
							semantic_token_resolution = {
								enabled = true,
								blocked_filetypes = { "java", "go", "c", "php" },
								-- How long to wait for semantic tokens to return before assuming no brackets should be added
								timeout_ms = 400,
							},
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
						border = nil, -- Defaults to `vim.o.winborder` on nvim 0.11+ or 'padded' when not defined/<=0.10
						winblend = 0,
						winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
						-- Note that the gutter will be disabled when border ~= 'none'
						scrollbar = true,
						-- Which directions to show the documentation window,
						-- for each of the possible menu window directions,
						-- falling back to the next direction when there's not enough space
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

				fuzzy = {
					-- Controls which implementation to use for the fuzzy matcher.
					--
					-- 'prefer_rust_with_warning' (Recommended) If available, use the Rust implementation, automatically downloading prebuilt binaries on supported systems. Fallback to the Lua implementation when not available, emitting a warning message.
					-- 'prefer_rust' If available, use the Rust implementation, automatically downloading prebuilt binaries on supported systems. Fallback to the Lua implementation when not available.
					-- 'rust' Always use the Rust implementation, automatically downloading prebuilt binaries on supported systems. Error if not available.
					-- 'lua' Always use the Lua implementation, doesn't download any prebuilt binaries
					--
					-- See the prebuilt_binaries section for controlling the download behavior
					implementation = "prefer_rust_with_warning",

					-- Allows for a number of typos relative to the length of the query
					-- Set this to 0 to match the behavior of fzf
					-- Note, this does not apply when using the Lua implementation.
					max_typos = function(keyword)
						return math.floor(#keyword / 4)
					end,

					-- Frecency tracks the most recently/frequently used items and boosts the score of the item
					-- Note, this does not apply when using the Lua implementation.
					frecency = {
						-- Whether to enable the frecency feature
						enabled = true,
						-- Location of the frecency database
						path = vim.fn.stdpath("state") .. "/blink/cmp/frecency.dat",
						-- UNSAFE!! When enabled, disables the lock and fsync when writing to the frecency database.
						-- This should only be used on unsupported platforms (e.g. alpine, termux)
						unsafe_no_lock = false,
					},

					-- Proximity bonus boosts the score of items matching nearby words
					-- Note, this does not apply when using the Lua implementation.
					use_proximity = true,

					-- Controls which sorts to use and in which order, falling back to the next sort if the first one returns nil
					-- You may pass a function instead of a string to customize the sorting
					--
					-- Optionally, set the table of sorts via a function instead: sorts = function() return { 'exact', 'score', 'sort_text' } end
					sorts = {
						-- (optionally) always prioritize exact matches
						-- 'exact',

						-- pass a function for custom behavior
						-- function(item_a, item_b)
						--   return item_a.score > item_b.score
						-- end,

						"exact",
						"score",
						"sort_text",
					},

					prebuilt_binaries = {
						-- Whether or not to automatically download a prebuilt binary from github. If this is set to `false`,
						-- you will need to manually build the fuzzy binary dependencies by running `cargo build --release`
						-- Disabled by default when `fuzzy.implementation = 'lua'`
						download = true,

						-- Ignores mismatched version between the built binary and the current git sha, when building locally
						ignore_version_mismatch = false,

						-- When downloading a prebuilt binary, force the downloader to resolve this version. If this is unset
						-- then the downloader will attempt to infer the version from the checked out git tag (if any).
						--
						-- You may set this to any pattern that `git describe --tags --match <pattern>` supports. For example,
						-- to track the latest release, you may set this to `v*`.
						--
						-- Beware that if the fuzzy matcher changes while tracking main then this may result in blink breaking.
						force_version = nil,

						-- When downloading a prebuilt binary, force the downloader to use this system triple. If this is unset
						-- then the downloader will attempt to infer the system triple from `jit.os` and `jit.arch`.
						-- Check the latest release for all available system triples
						--
						-- Beware that if the fuzzy matcher changes while tracking main then this may result in blink breaking.
						force_system_triple = nil,

						-- Extra arguments that will be passed to curl like { 'curl', ..extra_curl_args, ..built_in_args }
						extra_curl_args = {},

						proxy = {
							-- When downloading a prebuilt binary, use the HTTPS_PROXY environment variable
							from_env = true,

							-- When downloading a prebuilt binary, use this proxy URL. This will ignore the HTTPS_PROXY environment variable
							url = nil,
						},
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
		-- follow latest release.
		version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
		-- install jsregexp (optional!).
		build = "make install_jsregexp",
	},
}
