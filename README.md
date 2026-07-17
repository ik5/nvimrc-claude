# Neovim Configuration

A [LazyVim](https://lazyvim.org) based Neovim configuration tuned to feel like
a traditional, keyboard-centric Vim setup. LazyVim provides the foundation
(plugin management, LSP wiring, treesitter, formatting, testing, and sane
defaults), while this config overrides the parts that diverge from a classic
`nvimrc` workflow:

- Leader is `\` (backslash) instead of `<Space>`
- No mouse, no relative line numbers
- Standard bottom cmdline (noice.nvim disabled)
- Macro recording on `Q`, not `q`
- Extra AI, Git, and editor plugins described below

---

## Requirements

| Requirement                          | Notes                                                 |
| ------------------------------------ | ----------------------------------------------------- |
| **Neovim ≥ 0.11**                    | Required by LazyVim and several plugins               |
| **Git**                              | Plugin management via lazy.nvim                       |
| **A Nerd Font**                      | Icons in neo-tree, aerial, lualine, etc.              |
| **`ripgrep`** (`rg`)                 | Fuzzy grep via snacks.picker                          |
| **`fd`**                             | File finding via snacks.picker                        |
| **Node.js**                          | Many LSP servers install via npm                      |
| **`uuidgen`, `jq`, `xmllint`**       | `:GenerateUUID`, `:FormatJSON`, `:FormatXML` commands |
| **tmux** _(optional)_                | blink-cmp-tmux completion source                      |
| **`ANTHROPIC_API_KEY`** _(optional)_ | Required only for avante.nvim inline AI               |
| **`opencode`** _(optional)_          | OpenCode CLI; enables opencode.nvim when on `$PATH`   |
| **Flutter SDK** _(optional)_         | For Dart/Flutter projects (FVM, `$FLUTTER_ROOT`, or `PATH`) |

### External tool directories

Several options assume these directories exist. Create them before first launch:

```sh
mkdir -p ~/tmp/swp ~/tmp/vim_undo ~/tmp/spell ~/tmp
```

---

## Bootstrap (first install)

> If you already have a Neovim config, back it up first:
>
> ```sh
> mv ~/.config/nvim ~/.config/nvim.bak
> mv ~/.local/share/nvim ~/.local/share/nvim.bak   # plugin data
> ```

```sh
# 1. Clone this config
git clone <repo-url> ~/.config/nvim

# 2. Create runtime directories
mkdir -p ~/tmp/swp ~/tmp/vim_undo ~/tmp/spell

# 3. Launch Neovim — lazy.nvim bootstraps itself on the first run,
#    then installs all plugins automatically.
nvim
```

On the first launch lazy.nvim will:

1. Clone itself into `~/.local/share/nvim/lazy/lazy.nvim`
2. Download and install all plugins listed in `lua/config/lazy.lua`
3. Install LSP servers, formatters, and linters via Mason

You may see errors on the very first startup while Mason installs tools in the
background. Restart Neovim once installation finishes and everything will be
clean.

### Treesitter parsers

Parsers listed in `lua/plugins/languages.lua` install automatically via
`ensure_installed`. To install additional parsers manually:

```vim
:TSInstall <lang>
:TSInstallInfo          " custom command — shows all parsers and install status
```

### git: show untracked files inside new directories

Neogit follows git's status output. To see individual files inside a brand-new
untracked directory (instead of just `dirname/`), run once globally:

```sh
git config --global status.showUntrackedFiles all
```

---

## Configuration structure

```
~/.config/nvim/
├── init.lua                   # Entry point: leader, netrw disable, lazy bootstrap
├── lazy-lock.json             # Pinned plugin revisions (managed by lazy.nvim)
├── lazyvim.json               # LazyVim install metadata
├── key-mapping.md             # Full keymap reference ← see this for all bindings
├── README.md                  # This file
├── templates/
│   ├── nvim.lua               # Per-project .nvim.lua template (exrc)
│   └── neoconf.json           # Per-project .neoconf.json template (LSP)
└── lua/
    ├── ts_install_info.lua    # Custom :TSInstallInfo floating window
    ├── config/
    │   ├── lazy.lua           # Plugin list + LazyVim extras
    │   ├── options.lua        # Vim options (overrides LazyVim defaults)
    │   ├── keymaps.lua        # User keymaps (ported from old nvimrc)
    │   ├── autocmds.lua       # Autocommands + user commands
    │   ├── grep.lua           # ripgrep flag / filetype-scoping helpers
    │   ├── grep_finder.lua    # Patched snacks.picker grep finder (-v / no-col lines)
    │   ├── window_picker.lua  # Window-picker integration (snacks / aerial / neo-tree / qf)
    │   ├── quickfix.lua       # Quickfix buffer keymaps (<CR> / <C-x> / <C-v>)
    │   └── flutter_sdk.lua    # Flutter SDK auto-detection (FVM / FLUTTER_ROOT / PATH)
    └── plugins/
        ├── ai.lua             # claudecode.nvim + avante.nvim + opencode.nvim
        ├── bufferline.lua     # bufferline.nvim (tab/buffer line customisation)
        ├── colorscheme.lua    # monokai-pro (pro filter → monokai-pro-machine)
        ├── completion.lua     # blink.cmp extra sources + LuaSnip
        ├── explorer.lua       # neo-tree
        ├── flutter.lua        # flutter-tools.nvim + Dart LSP + Flutter keymaps
        ├── formatting.lua     # conform.nvim tweaks
        ├── fuzzy.lua          # snacks.picker config + git pickers + window-picker open
        ├── git.lua            # neogit + diffview.nvim
        ├── go.lua             # Go struct tags + interface stubs (gomodifytags, impl)
        ├── go-nvim.lua        # ray-x/go.nvim (comprehensive Go IDE features)
        ├── highlight.lua      # hlargs + rainbow-delimiters + eyeliner
        ├── keymaps.lua        # LazyVim keymap overrides (\cf → \lf)
        ├── languages.lua      # Extra LSP/treesitter + lsplinks (YAML/JSON $ref)
        ├── openapi.lua        # OpenAPI 3.x / Swagger 2.0 schema globs + content-detect
        ├── statusline.lua     # lualine extensions (block context, Flutter, char, clock)
        ├── symbols.lua        # aerial.nvim (symbol outline)
        ├── textobjects.lua    # nvim-various-textobjs
        ├── ui.lua             # Dashboard off, noice off, notifier timeout + indent
        ├── undotree.lua       # mbbill/undotree
        └── window-picker.lua  # nvim-window-picker (letter overlay for split navigation)
```

---

## Leader key

The leader is **`\`** (backslash).

LazyVim unconditionally overrides `mapleader` to `<Space>` inside its own
`options.lua`. To counter this the leader is set in **two** places:

1. `init.lua` — before lazy.nvim loads (affects plugin key specs)
2. `lua/config/options.lua` — after LazyVim's options run, before keymaps register

---

## Per-project configuration

`exrc` is enabled. Drop project-local overrides in the project root:

| File | Source template | Purpose |
| ---- | --------------- | ------- |
| `.nvim.lua` | `templates/nvim.lua` | Options, keymaps, conform overrides for one repo |
| `.neoconf.json` | `templates/neoconf.json` | LSP server settings (pyright path, gopls analyses, …) |

First time you open a project with `.nvim.lua`, run `:trust` (or `:trust!`) so Neovim
records approval under `~/.local/state/nvim/trust`.

---

## Installed plugins

### LazyVim extras (imported via `lua/config/lazy.lua`)

| Extra                   | What it adds                                             |
| ----------------------- | -------------------------------------------------------- |
| `editor.neo-tree`       | File explorer sidebar                                    |
| `editor.aerial`         | Symbol outline panel                                     |
| `editor.snacks_picker`  | Fuzzy finder (replaces Telescope)                        |
| `coding.mini-surround`  | Add/change/delete surrounding pairs                      |
| `lsp.neoconf`           | Per-project LSP config via `.neoconf.json`               |
| `editor.inc-rename`     | Live-preview rename across the buffer                    |
| `test.core`             | Test runner integration (neotest)                        |
| `ui.treesitter-context` | Sticky scroll — current function signature stays visible |
| `ai.claudecode`         | Claude Code CLI ↔ Neovim bridge                          |
| `ai.avante`             | Cursor-like inline AI panel (Anthropic API)              |
| `lang.go`               | Go LSP (gopls), gotest, gomodifytags, impl               |
| `lang.python`           | Python LSP (basedpyright), ruff                          |
| `lang.ruby`             | Ruby LSP, rubocop                                        |
| `lang.php`              | PHP LSP (phpactor)                                       |
| `lang.clangd`           | C / C++ / embedded (clangd)                              |
| `lang.rust`             | Rust LSP (rust-analyzer), cargo                          |
| `lang.sql`              | SQL LSP, formatter                                       |
| `lang.markdown`         | Markdown preview, formatting                             |
| `lang.typescript`       | TypeScript / JavaScript LSP (ts_ls)                      |
| `lang.docker`           | Dockerfile LSP                                           |
| `lang.yaml`             | YAML LSP, schema validation                              |
| `lang.json`             | JSON LSP, schema validation                              |
| `lang.toml`             | TOML LSP                                                 |

### User plugins (via `lua/plugins/`)

#### Git

| Plugin                                       | Purpose                                                                                                                          |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **neogit** (`NeogitOrg/neogit`)              | Magit-like git panel: stage, commit, push, pull, fetch, branches, tags, remotes, log, rebase, stash. Opens as a floating window. |
| **diffview.nvim** (`sindrets/diffview.nvim`) | Full-screen side-by-side diff and file history with word-level highlights.                                                       |
| **gitsigns.nvim**                            | Inline hunk staging, blame, and diff (provided by LazyVim base).                                                                 |
| **snacks.picker** git pickers                | Git log, file log, branches, status, stash, diff hunks.                                                                          |

#### File navigation

| Plugin                 | Purpose                                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------------------------- |
| **neo-tree.nvim**      | Left-sidebar file explorer with git status, diagnostics, and dotfile visibility. Toggle with `F3`.            |
| **nvim-window-picker** | Floating letter overlay to pick which split to open a file into.                                              |
| **snacks.picker**      | Fuzzy finder for files, buffers, grep, LSP symbols, help, man pages, and more.                                |
| **flash.nvim**         | Jump anywhere on screen with 1-2 keystrokes (LazyVim built-in).                                               |
| **eyeliner.nvim**      | Always-on highlights showing unique characters on the current line for `f`/`t` jumps. Complements flash.nvim. |

#### LSP & completion

| Plugin                 | Purpose                                                                                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **nvim-lspconfig**     | LSP client configuration (LazyVim base + HTML, CSS, Bash, Emmet, SchemaStore-backed JSON/YAML).                                                                |
| **lsplinks.nvim**      | Navigate YAML/JSON `$ref` document links from yamlls/jsonls (incl. OpenAPI). Bound to `gL`.                                                                  |
| **OpenAPI / Swagger**  | Extra globs + content-detect for OpenAPI 3.x / Swagger 2.0 via yamlls + jsonls (`lua/plugins/openapi.lua`). Manual: `:OpenApiSchema [3\|2]`.                  |
| **blink.cmp**          | Completion engine with LSP, path, snippets, buffer sources (LazyVim base). Extended with: `spell` (dictionary), `tmux` (visible panes), `omni` (vim omnifunc). |
| **conform.nvim**       | Auto-formatting on save (LazyVim base). Format key moved to `\lf`.                                                                                             |
| **aerial.nvim**        | Symbol outline panel on the right (full editor height). Toggle with `F4`. Shows LSP detail (full signatures).                                                  |
| **treesitter-context** | Sticky scroll — keeps the function/class signature pinned at the top when scrolled out of view.                                                                |

#### Editing

| Plugin                    | Purpose                                                                                                                                           |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| **mini.surround**         | Add (`sa`), delete (`sd`), replace (`sr`) surrounding pairs.                                                                                      |
| **inc-rename**            | Rename symbol with live preview across the buffer.                                                                                                |
| **nvim-various-textobjs** | Extra text objects: subword (`iS`), indentation (`ii`), value (`iv`), key (`ik`), chain member (`im`), file path (`iF`), colour (`i#`), and more. |
| **undotree**              | Visual undo branch history with diff panel. Toggle with `F6`. Persistent undo stored in `~/tmp/vim_undo/`.                                        |

#### Highlighting

| Plugin                 | Purpose                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------- |
| **hlargs.nvim**        | Highlights function argument names in declarations and every usage inside the body (treesitter-powered). |
| **rainbow-delimiters** | Rainbow-coloured parentheses / brackets / braces up to 7 nesting levels.                                 |
| **eyeliner.nvim**      | Per-line unique-character hints for `f`/`t` targets.                                                     |

#### Go-specific tools

| Plugin / File          | Purpose                                                                                                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------------- |
| **ray-x/go.nvim**      | Comprehensive Go IDE: auto goimports, gofumpt, codelens, golangci-lint, test runner. Loaded on `CmdlineEnter` or Go files. |
| **go.lua keymaps**     | `<leader>gta/gto/gtr/gtx` — struct tag add/options/remove/clear via gomodifytags. `<leader>gI` — interface stubs via impl. Buffer-local (Go files only). |

#### Flutter / Dart

| Plugin / File                | Purpose                                                                                                              |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **flutter-tools.nvim** (`nvim-flutter/flutter-tools.nvim`) | Full Flutter IDE: manages dartls itself (do **not** enable `lang.dart` extra), hot reload/restart, device picker, widget outline, dev log. |
| **neotest-dart**             | Dart/Flutter test runner via neotest.                                                                                |
| **`lua/config/flutter_sdk.lua`** | Auto-detects the Flutter SDK: project `.fvm/flutter_sdk` → FVM version cache → `$FLUTTER_ROOT` → `PATH` → common install dirs. Re-runs on `DirChanged` / before dart attach. |
| **`:FlutterSdkInfo`**        | Shows the resolved Flutter SDK path and source. See User commands below.                                            |

> **Note:** `flutter-tools.nvim` configures `dartls` internally. The LazyVim `lang.dart` extra must **not** be imported — it would register a second dartls via lspconfig and cause conflicts.

#### AI

| Plugin              | Keys        | Purpose                                                                                                     |
| ------------------- | ----------- | ----------------------------------------------------------------------------------------------------------- |
| **claudecode.nvim** | `\a` prefix | Bridges the Claude Code CLI (`claude` command in terminal) with Neovim — reads/writes buffers, shows diffs. |
| **avante.nvim**     | `\A` prefix | Inline AI panel: chat (`\Ac`), ask (`\Aa`), edit selection (`\Ae`), and more. Requires `ANTHROPIC_API_KEY`. |
| **opencode.nvim**   | `\o` prefix | OpenCode CLI integration (loaded only when `opencode` is on `$PATH`). Toggle panel (`\oo`), ask (`\oa`), select action (`\os`). Uses snacks.terminal on the right. |

#### UI

| Plugin              | Purpose                                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **monokai-pro**     | Colorscheme (`filter = "pro"`; LazyVim colorscheme name: `monokai-pro-machine`). |
| **bufferline.nvim** | Buffer/tab line with LSP diagnostic indicators, custom icons via mini.icons, and buffer-number labels. |
| **lualine**         | Status line (LazyVim base). Extended: `lualine_c` shows treesitter block context (if/for/while); `lualine_x` shows Flutter device/version (Dart) · char value · EOL type · filetype; `lualine_z` shows `⌚HH:MM Weekday DD/MM/YYYY📅`. |
| **snacks.notifier** | Notification popups (noice.nvim disabled). Timeout: 15 s (default); if `DEBUG_MESSAGES` is a number → that many ms; if set to any non-numeric value → 90 000 ms. |

---

## Notable differences from vanilla LazyVim

| Setting             | LazyVim default | This config                                       |
| ------------------- | --------------- | ------------------------------------------------- |
| `mapleader`         | `<Space>`       | `\` (backslash)                                   |
| `relativenumber`    | on              | off by default (toggle with `\rel`)               |
| `mouse`             | `a` (all)       | disabled                                          |
| `wrap`              | off             | on (with `linebreak`, `breakindent`)              |
| `cmdheight`         | 0               | 2 (noice is disabled)                             |
| `colorcolumn`       | —               | 120                                               |
| `textwidth`         | —               | 120                                               |
| `spell`             | off             | on (`en_us` + `en`; RTL typing via F8/F9)         |
| `F2`                | —               | smart buffer/window close (see key-mapping.md)    |
| `timeout`           | on              | off (only `ttimeoutlen`)                          |
| Format key          | `\cf`           | `\lf` (`\cf` kept for cross-instance paste)       |
| Quit all            | `\qq` / `\qa`   | `\Qq` / `\Qa`                                     |
| noice.nvim          | enabled         | disabled                                          |
| dashboard           | enabled         | disabled                                          |
| lazygit             | `\gg`           | removed (use neogit `\gn` instead)                |
| `q` key             | macro record    | disabled (use `Q` to record, `M` to execute `@q`) |
| Swap files          | `~/.swp`        | `~/tmp/swp//`                                     |
| Undo files          | `~/.vim/undo`   | `~/tmp/vim_undo/`                                 |
| Notifier timeout    | 3 s             | 15 s default; see `DEBUG_MESSAGES` env var        |
| Trailing whitespace | —               | highlighted + trimmed on save                     |
| Indent defaults     | 2-space soft tabs | 2-space soft tabs (Go: hard tabs via autocmd)  |

---

## User commands

| Command                          | Description                                                                                          |
| -------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `:DiagNext` / `:DiagPrev`        | Jump to next/prev diagnostic, auto-open float                                                        |
| `:DiagNextError` / `:DiagPrevError` | Jump to next/prev **error**, auto-open float                                                      |
| `:DiagNextWarn` / `:DiagPrevWarn`   | Jump to next/prev **warning**, auto-open float                                                    |
| `:DiagInfo`                      | Show diagnostic detail float under cursor (source + code)                                            |
| `:DiagLine`                      | Show all diagnostics on the current line (float)                                                     |
| `:DiagList`                      | Open workspace diagnostics in Trouble                                                                |
| `:DiagBufList`                   | Open current-buffer diagnostics in Trouble                                                           |
| `:TSInstallInfo`                 | Interactive treesitter grammar list: install/uninstall/update, filter installed/missing (see key-mapping.md) |
| `:Messages`                      | Show snacks.nvim notification history (plugin `vim.notify` calls)                                    |
| `:Term`                          | Open a terminal in a horizontal split (starts in insert)                                             |
| `:VTerm`                         | Open a terminal in a vertical split (starts in insert)                                               |
| `:FormatJSON`                    | Format selected/whole-file JSON via `jq`                                                             |
| `:FormatXML`                     | Format selected/whole-file XML via `xmllint`                                                         |
| `:GenerateUUID`                  | Insert a new UUID at the cursor (`uuidgen`)                                                          |
| `:ReloadFile [buf…]`             | Reload current buffer (or named open buffers) from disk, keeping cursor position                     |
| `:LspRename [name]`              | Rename symbol under cursor via LSP (optional new name as argument)                                   |
| `:LspInfo`                       | Show LSP health / active client status (`:checkhealth vim.lsp`)                                      |
| `:LspLog`                        | Open the LSP log file                                                                                |
| `:LspLogLevel <level>`           | Set LSP log verbosity: `trace` / `debug` / `info` / `warn` / `error` / `off`                        |
| `:LspRestart`                    | Restart all LSP clients attached to the current buffer                                               |
| `:BlinkClearFrequency`           | Clear blink.cmp frecency cache (`stdpath("state")/blink/cmp/frecency.dat`)                           |
| `:FlutterSdkInfo`                | Show resolved Flutter SDK path and detection source. Available after opening a `.dart` file.         |
| `:OpenApiSchema [3\|2]`          | Bind OpenAPI 3.x or Swagger 2.0 JSON Schema to the current YAML/JSON buffer (auto-detects if omitted) |

---

## Environment variables

| Variable                      | Effect                                                              |
| ----------------------------- | ------------------------------------------------------------------- |
| `DEBUG_MESSAGES=<number>`     | Notification timeout → that many **milliseconds** (e.g. `90000`)   |
| `DEBUG_MESSAGES=<non-number>` | Notification timeout → 90 000 ms (e.g. `DEBUG_MESSAGES=yes`)       |
| _(unset)_                     | Notification timeout → 15 000 ms (15 s)                            |
| `ANTHROPIC_API_KEY`           | Required for avante.nvim (inline AI panel)                         |
| `TMUX`                        | Enables blink-cmp-tmux completion source automatically              |
| `FLUTTER_ROOT`                | Preferred Flutter SDK root (must contain `bin/flutter`)            |

---

## Key mappings

See **[key-mapping.md](key-mapping.md)** for the full reference — every
keymap organised by plugin and mode, with descriptions and a table of contents.

Quick orientation:

| Prefix | Domain                                                                 |
| ------ | ---------------------------------------------------------------------- |
| `\a`   | Claude Code CLI (claudecode.nvim)                                      |
| `\A`   | Avante inline AI                                                       |
| `\o`   | OpenCode CLI (when `opencode` is installed)                            |
| `\F`   | Flutter / Dart tools (buffer-local in `.dart` files)                   |
| `\g`   | Git (gitsigns, snacks, neogit, diffview)                               |
| `\G`   | Git diff hunks / origin diff                                           |
| `\l`   | LSP actions (`\lf` = format)                                           |
| `\b`   | Buffers                                                                |
| `\s`   | Search / pickers                                                       |
| `\Q`   | Quit (`\Qq` quit-all, `\Qa` quit-all-force)                            |
| `F2`   | Smart close: sidebar/special → close win; else delete buffer (safe)    |
| `F3`   | Toggle neo-tree explorer                                               |
| `F4`   | Toggle aerial symbol outline                                           |
| `F5`   | Toggle search highlight                                                |
| `F6`   | Toggle undotree                                                        |
| `F8`   | Toggle reverse-insert (Hebrew/Arabic)                                  |
| `F9`   | Toggle right-to-left mode (Hebrew/Arabic)                              |
| `gL`   | Follow LSP document link (`$ref` in YAML/JSON)                         |
