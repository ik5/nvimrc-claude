# Neovim Configuration

A [LazyVim](https://lazyvim.org) based Neovim configuration tuned to feel like
a traditional, keyboard-centric Vim setup. LazyVim provides the foundation
(plugin management, LSP wiring, treesitter, formatting, testing, and sane
defaults), while this config overrides the parts that diverge from a classic
`nvimrc` workflow:

- Leader is `\` (backslash) instead of `<Space>`
- No mouse, no relative line numbers
- 4-space soft tabs instead of 2-space
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
| **`uuidgen`**                        | `:GenerateUUID` command                               |
| **`uuidgen`, `jq`, `xmllint`**       | `:GenerateUUID`, `:FormatJSON`, `:FormatXML` commands |
| **tmux** _(optional)_                | blink-cmp-tmux completion source                      |
| **`ANTHROPIC_API_KEY`** _(optional)_ | Required only for avante.nvim inline AI               |

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
├── lua/
│   ├── config/
│   │   ├── lazy.lua           # Plugin list + LazyVim extras
│   │   ├── options.lua        # Vim options (overrides LazyVim defaults)
│   │   ├── keymaps.lua        # User keymaps (ported from old nvimrc)
│   │   └── autocmds.lua       # Autocommands + user commands
│   └── plugins/
│       ├── ai.lua             # claudecode.nvim + avante.nvim
│       ├── colorscheme.lua    # monokai-pro (pro filter)
│       ├── completion.lua     # blink.cmp extra sources
│       ├── explorer.lua       # neo-tree + window-picker
│       ├── formatting.lua     # conform.nvim tweaks
│       ├── fuzzy.lua          # snacks.picker config + git pickers
│       ├── git.lua            # neogit + diffview.nvim
│       ├── go.lua             # Go struct tags + interface stubs
│       ├── highlight.lua      # hlargs + rainbow-delimiters + eyeliner
│       ├── keymaps.lua        # LazyVim keymap overrides
│       ├── languages.lua      # Extra LSP/treesitter (HTML/CSS/Bash/…)
│       ├── refactoring.lua    # refactoring.nvim tweaks
│       ├── symbols.lua        # aerial.nvim (symbol outline)
│       ├── textobjects.lua    # nvim-various-textobjs
│       ├── ui.lua             # Dashboard off, noice off, notifier timeout
│       └── undotree.lua       # mbbill/undotree
├── key-mapping.md             # Full keymap reference ← see this for all bindings
└── README.md                  # This file
```

---

## Leader key

The leader is **`\`** (backslash).

LazyVim unconditionally overrides `mapleader` to `<Space>` inside its own
`options.lua`. To counter this the leader is set in **two** places:

1. `init.lua` — before lazy.nvim loads (affects plugin key specs)
2. `lua/config/options.lua` — after LazyVim's options run, before keymaps register

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
| `editor.refactoring`    | Code refactoring actions (extract function, etc.)        |
| `test.core`             | Test runner integration (neotest)                        |
| `ui.treesitter-context` | Sticky scroll — current function signature stays visible |
| `ai.claudecode`         | Claude Code CLI ↔ Neovim bridge                          |
| `ai.avante`             | Cursor-like inline AI panel (Anthropic API)              |
| `lang.go`               | Go LSP, gopls, gotest, gomodifytags, impl                |
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
| **nvim-lspconfig**     | LSP client configuration (LazyVim base + HTML, CSS, Bash, Emmet).                                                                                              |
| **blink.cmp**          | Completion engine with LSP, path, snippets, buffer sources (LazyVim base). Extended with: `spell` (dictionary), `tmux` (visible panes), `omni` (vim omnifunc). |
| **conform.nvim**       | Auto-formatting on save (LazyVim base). Format key moved to `\lf`.                                                                                             |
| **aerial.nvim**        | Symbol outline panel on the right. Toggle with `F4`. Shows LSP detail (full signatures).                                                                       |
| **treesitter-context** | Sticky scroll — keeps the function/class signature pinned at the top when scrolled out of view.                                                                |

#### Editing

| Plugin                    | Purpose                                                                                                                                           |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| **mini.surround**         | Add (`sa`), delete (`sd`), replace (`sr`) surrounding pairs.                                                                                      |
| **inc-rename**            | Rename symbol with live preview across the buffer.                                                                                                |
| **refactoring.nvim**      | Extract function/variable, inline variable, and more.                                                                                             |
| **nvim-various-textobjs** | Extra text objects: subword (`iS`), indentation (`ii`), value (`iv`), key (`ik`), chain member (`im`), file path (`iF`), colour (`i#`), and more. |
| **undotree**              | Visual undo branch history with diff panel. Toggle with `F6`. Persistent undo stored in `~/tmp/vim_undo/`.                                        |

#### Highlighting

| Plugin                 | Purpose                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------- |
| **hlargs.nvim**        | Highlights function argument names in declarations and every usage inside the body (treesitter-powered). |
| **rainbow-delimiters** | Rainbow-coloured parentheses / brackets / braces up to 7 nesting levels.                                 |
| **eyeliner.nvim**      | Per-line unique-character hints for `f`/`t` targets.                                                     |

#### AI

| Plugin              | Keys        | Purpose                                                                                                     |
| ------------------- | ----------- | ----------------------------------------------------------------------------------------------------------- |
| **claudecode.nvim** | `\a` prefix | Bridges the Claude Code CLI (`claude` command in terminal) with Neovim — reads/writes buffers, shows diffs. |
| **avante.nvim**     | `\A` prefix | Inline AI panel: chat (`\Ac`), ask (`\Aa`), edit selection (`\Ae`), and more. Requires `ANTHROPIC_API_KEY`. |

#### UI

| Plugin              | Purpose                                                                                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **monokai-pro**     | Colorscheme (pro filter).                                                                                                                               |
| **lualine**         | Status line (LazyVim base).                                                                                                                             |
| **snacks.notifier** | Notification popups (noice.nvim disabled). Timeout: 60 s normal, 90 s when `DEBUG_MESSAGES` is set, or the value of `DEBUG_MESSAGES` if it is a number. |

---

## Notable differences from vanilla LazyVim

| Setting          | LazyVim default | This config                                       |
| ---------------- | --------------- | ------------------------------------------------- |
| `mapleader`      | `<Space>`       | `\` (backslash)                                   |
| `relativenumber` | on              | off by default (toggle with `\rel`)               |
| `mouse`          | `a` (all)       | disabled                                          |
| `wrap`           | off             | on (with `linebreak`, `breakindent`)              |
| `cmdheight`      | 0               | 2 (noice is disabled)                             |
| `colorcolumn`    | —               | 120                                               |
| `textwidth`      | —               | 120                                               |
| `spell`          | off             | on (English + Hebrew)                             |
| `timeout`        | on              | off (only `ttimeoutlen`)                          |
| Format key       | `\cf`           | `\lf` (`\cf` kept for cross-instance paste)       |
| Quit all         | `\qq` / `\qa`   | `\Qq` / `\Qa`                                     |
| noice.nvim       | enabled         | disabled                                          |
| dashboard        | enabled         | disabled                                          |
| lazygit          | `\gg`           | removed (use neogit `\gn` instead)                |
| `q` key          | macro record    | disabled (use `Q` to record, `M` to execute `@q`) |
| Swap files       | `~/.swp`        | `~/tmp/swp//`                                     |
| Undo files       | `~/.vim/undo`   | `~/tmp/vim_undo/`                                 |

---

## User commands

| Command                     | Description                                                                       |
| --------------------------- | --------------------------------------------------------------------------------- |
| `:DiagNext`                 | Jump to next diagnostic, auto-open float                                          |
| `:DiagPrev`                 | Jump to previous diagnostic, auto-open float                                      |
| `:DiagNextE` / `:DiagPrevE` | Jump to next/prev **error**                                                       |
| `:DiagNextW` / `:DiagPrevW` | Jump to next/prev **warning**                                                     |
| `:DiagInfo`                 | Show diagnostic detail float under cursor                                         |
| `:TSInstallInfo`            | Show treesitter parser install status (recreated — removed in nvim-treesitter v1) |
| `:Messages`                 | Open `:messages` output in a scratch buffer                                       |
| `:Term`                     | Open a terminal in a horizontal split                                             |
| `:VTerm`                    | Open a terminal in a vertical split                                               |
| `:FormatJSON`               | Format selected/whole-file JSON via `jq`                                          |
| `:FormatXML`                | Format selected/whole-file XML via `xmllint`                                      |
| `:GenerateUUID`             | Insert a new UUID at the cursor (`uuidgen`)                                       |
| `:ReloadFile [buf…]`        | Reload current buffer (or named buffers) from disk, keeping cursor position       |

---

## Environment variables

| Variable              | Effect                                                 |
| --------------------- | ------------------------------------------------------ |
| `DEBUG_MESSAGES=1`    | Notification timeout → 90 000 ms                       |
| `DEBUG_MESSAGES=5000` | Notification timeout → 5 000 ms (any integer)          |
| `ANTHROPIC_API_KEY`   | Required for avante.nvim (inline AI panel)             |
| `TMUX`                | Enables blink-cmp-tmux completion source automatically |

---

## Key mappings

See **[key-mapping.md](key-mapping.md)** for the full reference — every
keymap organised by plugin and mode, with descriptions and a table of contents.

Quick orientation:

| Prefix | Domain                                              |
| ------ | --------------------------------------------------- |
| `\a`   | Claude Code CLI (claudecode.nvim)                   |
| `\A`   | Avante inline AI                                    |
| `\g`   | Git (gitsigns, snacks, neogit, diffview)            |
| `\G`   | Git diff hunks / origin diff                        |
| `\l`   | LSP actions (`\lf` = format)                        |
| `\b`   | Buffers                                             |
| `\s`   | Search / pickers                                    |
| `\Q`   | Quit (`\Qq` quit-all, `\Qa` quit-all-force)         |
| `F2`   | Close current split (safe — won't exit last window) |
| `F3`   | Toggle neo-tree explorer                            |
| `F4`   | Toggle aerial symbol outline                        |
| `F5`   | Toggle search highlight                             |
| `F6`   | Toggle undotree                                     |
| `F8`   | Toggle reverse-insert (Hebrew/Arabic)               |
| `F9`   | Toggle right-to-left mode (Hebrew/Arabic)           |
