# Neovim Key Mapping Reference

> **Leader key**: `\` (backslash)
> **Local leader**: `\` (backslash)
> Modes: `n` = Normal · `i` = Insert · `v` = Visual · `o` = Operator-pending · `t` = Terminal · `c` = Command

---

## Table of Contents

1. [Conventions & Picker Keys](#1-conventions--picker-keys)
2. [Escape / Mode Exit](#2-escape--mode-exit)
3. [Window Navigation](#3-window-navigation)
4. [Window & Split Management](#4-window--split-management)
5. [Buffer Management](#5-buffer-management)
6. [Tabs](#6-tabs)
7. [Search](#7-search)
8. [Movement](#8-movement)
9. [Text Editing](#9-text-editing)
10. [Clipboard & Yank](#10-clipboard--yank)
11. [Macros](#11-macros)
12. [Display Toggles](#12-display-toggles)
13. [Grep (ripgrep)](#13-grep-ripgrep)
14. [Terminal](#14-terminal)
15. [Right-to-Left (Hebrew / Arabic)](#15-right-to-left-hebrew--arabic)
16. [User Commands](#16-user-commands)
    - [Diagnostic Commands](#diagnostic-commands)
    - [Terminal Commands](#terminal-commands)
    - [Format Commands](#format-commands)
    - [LSP Commands](#lsp-commands)
    - [Utility Commands](#utility-commands)
17. [LSP](#17-lsp)
18. [Diagnostics (keymaps)](#18-diagnostics-keymaps)
19. [Git — Inline Hunks (gitsigns)](#19-git--inline-hunks-gitsigns)
20. [Git — Pickers (snacks)](#20-git--pickers-snacks)
21. [Git — Neogit](#21-git--neogit)
22. [Git — Diffview](#22-git--diffview)
23. [File Explorer (neo-tree)](#23-file-explorer-neo-tree)
24. [Symbol Outline (aerial)](#24-symbol-outline-aerial)
25. [Fuzzy Finder (snacks.picker)](#25-fuzzy-finder-snackspicker)
26. [Search & Replace (grug-far)](#26-search--replace-grug-far)
27. [Navigation (flash.nvim)](#27-navigation-flashnvim)
28. [Undo Tree](#28-undo-tree)
29. [Refactoring](#29-refactoring)
30. [Text Objects](#30-text-objects)
31. [Go Language Tools](#31-go-language-tools)
32. [AI — Claude Code](#32-ai--claude-code)
33. [AI — Avante](#33-ai--avante)
34. [UI Toggles (snacks)](#34-ui-toggles-snacks)
35. [Windows & Tabs (LazyVim)](#35-windows--tabs-lazyvim)
36. [Trouble (diagnostics list)](#36-trouble-diagnostics-list)
37. [Todo Comments](#37-todo-comments)
38. [Formatting](#38-formatting)
39. [Keymap Conflicts Resolved](#39-keymap-conflicts-resolved)

---

## 1. Conventions & Picker Keys

These keys apply inside any **snacks.picker** or **neo-tree** window:

| Key | Mode | Action |
|-----|------|--------|
| `<C-x>` | n/i | Open selection in horizontal split |
| `<C-v>` | n/i | Open selection in vertical split |
| `w` | n | Pick destination window, then open |

---

## 2. Escape / Mode Exit

| Key | Mode | Action |
|-----|------|--------|
| `XX` | i | Exit insert mode (`<Esc>`) |
| `XX` | c | Exit command mode (`<C-c>`) |
| `XX` | o | Exit operator-pending (`<Esc>`) |
| `XX` | v | Exit visual, keep selection (`<Esc>gV`) |
| `XX` | n | Clear search highlight + escape |
| `XX` | t | Exit terminal mode (`<C-\><C-n>`) |
| `<leader><ESC>` | t | Exit terminal mode |
| `<A-[>` | t | Exit terminal mode |

---

## 3. Window Navigation

| Key | Mode | Action |
|-----|------|--------|
| `<C-H>` / `<C-h>` | n, i | Move to left window |
| `<C-J>` / `<C-j>` | n, i | Move to window below |
| `<C-K>` / `<C-k>` | n, i | Move to window above |
| `<C-L>` / `<C-l>` | n, i | Move to right window |
| `<C-Left>` | n, i, t | Move to left window |
| `<C-Right>` | n, i, t | Move to right window |
| `<C-Up>` | n, i, t | Move to window above |
| `<C-Down>` | n, i, t | Move to window below |

---

## 4. Window & Split Management

| Key | Mode | Action |
|-----|------|--------|
| `<leader>q` | n | Close all windows except active (`:only`) |
| `<C-W>` | i | Window command prefix in insert mode |
| `-` | n | Decrease window height (`<C-W>-`) |
| `+` | n | Increase window height (`<C-W>+`) |
| `<M-,>` | n | Decrease window width (`<C-W>>`) |
| `<M-.>` | n | Increase window width (`<C-W><`) |
| `<F2>` | n | Close current split (never exits if last window) |
| `<Leader>=` | n | Equalize all split sizes |
| `<leader>-` | n | Split window below (LazyVim) |
| `<leader>\|` | n | Split window right (LazyVim) |
| `<leader>wd` | n | Delete window (LazyVim) |
| `<leader>wm` | n | Toggle window zoom (LazyVim) |

---

## 5. Buffer Management

| Key | Mode | Action |
|-----|------|--------|
| `<leader>d` | n | Delete buffer, keep window open (`Snacks.bufdelete`) |
| `<leader>D` | n | Wipeout buffer, keep window open (`Snacks.bufdelete wipeout`) |
| `<M-d>` | n | Next buffer |
| `<M-a>` | n | Previous buffer |
| `<leader>bfn` | n | Next buffer |
| `<leader>bfp` | n | Previous buffer |
| `<Space>x` | n | Go to next buffer, delete current |
| `<C-b>b` | n | Switch to alternate buffer (`<C-^>`) |
| `<C-b>n` | n | Next buffer |
| `<C-b>p` | n | Previous buffer |
| `<S-h>` | n | Previous buffer (LazyVim) |
| `<S-l>` | n | Next buffer (LazyVim) |
| `[b` / `]b` | n | Previous / next buffer (LazyVim) |
| `<leader>bb` | n | Switch to other buffer (LazyVim) |
| `<leader>bd` | n | Delete buffer (LazyVim) |
| `<leader>bo` | n | Delete other buffers (LazyVim) |
| `<leader>bD` | n | Delete buffer and window (LazyVim) |
| `<leader>fn` | n | New file (LazyVim) |

---

## 6. Tabs

| Key | Mode | Action |
|-----|------|--------|
| `<C-PageDown>` | n | Next tab |
| `<C-PageUp>` | n | Previous tab |
| `<C-O>` | n | Open new tab (prompts for name) |
| `<C-T>` | n | Open empty new tab |
| `<leader><tab><tab>` | n | New tab (LazyVim) |
| `<leader><tab>]` | n | Next tab (LazyVim) |
| `<leader><tab>[` | n | Previous tab (LazyVim) |
| `<leader><tab>l` | n | Last tab (LazyVim) |
| `<leader><tab>f` | n | First tab (LazyVim) |
| `<leader><tab>d` | n | Close tab (LazyVim) |
| `<leader><tab>o` | n | Close other tabs (LazyVim) |

---

## 7. Search

| Key | Mode | Action |
|-----|------|--------|
| `<F5>` | n | Toggle search highlight |
| `<leader><F5>` | n | Clear last search register |
| `n` | n | Next match, centered |
| `N` | n | Previous match, centered |
| `<Esc>` | n | Clear search highlight (LazyVim) |
| `<leader>ur` | n | Redraw + clear hlsearch + diff update (LazyVim) |

---

## 8. Movement

| Key | Mode | Action |
|-----|------|--------|
| `<C-d>` | n | Half-page down, centered |
| `<C-u>` | n | Half-page up, centered |
| `j` | n | Down (respects wrapped lines) |
| `k` | n | Up (respects wrapped lines) |
| `<M-j>` | n | Move current line down |
| `<M-k>` | n | Move current line up |
| `<M-j>` | v | Move selected lines down |
| `<M-k>` | v | Move selected lines up |
| `gx` | n | Swap current char with next |
| `gX` | n | Swap current char with previous |
| `gl` | n | Swap current word with previous |
| `gr` | n | Swap current word with next |
| `g{` | n | Swap paragraph with previous |
| `g}` | n | Swap paragraph with next |

---

## 9. Text Editing

| Key | Mode | Action |
|-----|------|--------|
| `g=` | n | Re-indent last changed text |
| `<leader>srt` | n, v | Sort paragraph |
| `<S-Tab>` | n, i, v | Convert tabs to spaces (`:retab`) |
| `<C-s>` | n, i, v | Save file (LazyVim) |
| `gco` | n | Add comment below cursor (LazyVim) |
| `gcO` | n | Add comment above cursor (LazyVim) |
| `<` / `>` | v | Indent left/right, keep selection (LazyVim) |
| `,` `.` `;` | i | Insert undo break-points (LazyVim) |

---

## 10. Clipboard & Yank

| Key | Mode | Action |
|-----|------|--------|
| `<leader>p` | n | Paste and re-indent |
| `<leader>P` | n | Paste before and re-indent |
| `<leader>y` | v | Copy selection to `~/.tmp/.vbuf` |
| `<leader>y` | n | Copy current line to `~/.tmp/.vbuf` |
| `<leader>cf` | n | Paste from `~/.tmp/.vbuf` |
| `Y` | n | Yank to end of line |
| `gp` | n | Visually reselect last yank |

---

## 11. Macros

| Key | Mode | Action |
|-----|------|--------|
| `q` | n | **Disabled** (prevents accidental recording) |
| `Q` | n | Record macro (replaces `q`) |
| `M` | n | Execute macro from register `q` |
| `M` | v | Execute macro on each line of selection |

---

## 12. Display Toggles

| Key | Mode | Action |
|-----|------|--------|
| `<leader>hc` | n, i | Toggle hidden characters (listchars) |
| `<leader>wrp` | n, i | Toggle word wrap |
| `<leader>rel` | n, i | Toggle relative line numbers |
| `<leader>curc` | n, i | Toggle cursor column |
| `<leader>curr` | n, i | Toggle cursor line |
| `<C-f>` | n | Print full file path |
| `<leader>R` | n | Reload `init.lua` config |
| `<leader>W` | n | Force save file (`:w!`) |

---

## 13. Grep (ripgrep)

| Key | Mode | Action |
|-----|------|--------|
| `gw` | n | Grep word under cursor (whole word) |
| `g/` | n | Grep prompt (free input) |
| `g*` | n | Grep word under cursor (partial match) |
| `ga` | n | Grep add (append results to quickfix) |
| `,f` | n | `:find ` prompt |
| `,s` | n | `:sfind ` (split find) |
| `,v` | n | `:vert sfind ` (vsplit find) |
| `,t` | n | `:tabfind ` |

---

## 14. Terminal

| Key | Mode | Action |
|-----|------|--------|
| `<leader>T` | n | Open terminal in current window |
| `<leader>ft` | n | Terminal (project root dir) (LazyVim) |
| `<leader>fT` | n | Terminal (cwd) (LazyVim) |
| `<C-/>` | n | Terminal (root dir) (LazyVim) |

---

## 15. Right-to-Left (Hebrew / Arabic)

| Key | Mode | Action |
|-----|------|--------|
| `<F9>` | n, i | Toggle right-to-left mode |
| `<F8>` | n, i | Toggle reverse insert mode |

---

## 16. User Commands

### Diagnostic Commands

| Command | Description |
|---------|-------------|
| `:DiagNext` | Jump to next diagnostic, open detail float |
| `:DiagPrev` | Jump to previous diagnostic, open detail float |
| `:DiagNextError` | Jump to next error, open detail float |
| `:DiagPrevError` | Jump to previous error, open detail float |
| `:DiagNextWarn` | Jump to next warning, open detail float |
| `:DiagPrevWarn` | Jump to previous warning, open detail float |
| `:DiagInfo` | Show diagnostic detail at cursor (source + code) |
| `:DiagLine` | Show all diagnostics on current line (float) |
| `:DiagList` | Open all workspace diagnostics in Trouble |
| `:DiagBufList` | Open current buffer diagnostics in Trouble |

### Terminal Commands

| Command | Description |
|---------|-------------|
| `:Term` | Open terminal in horizontal split (starts in insert mode) |
| `:VTerm` | Open terminal in vertical split (starts in insert mode) |

### Format Commands

| Command | Description |
|---------|-------------|
| `:FormatJSON [range]` | Pretty-print JSON via `jq` (defaults to whole file) |
| `:FormatXML [range]` | Pretty-print XML via `xmllint` (defaults to whole file) |

### LSP Commands

| Command | Description |
|---------|-------------|
| `:LspRename [name]` | Rename symbol under cursor via LSP; optional new name as argument |
| `:LspInfo` | Show LSP health / active client status (`:checkhealth vim.lsp`) |
| `:LspLog` | Open the LSP log file in a buffer |
| `:LspLogLevel <level>` | Set LSP log verbosity: `trace` / `debug` / `info` / `warn` / `error` / `off` |
| `:LspRestart` | Restart all LSP clients on the current buffer |

### Utility Commands

| Command | Description |
|---------|-------------|
| `:ReloadFile [files...]` | Reload current buffer (or named open buffers) from disk, keeping cursor position. Tab-completes open buffer names. |
| `:GenerateUUID` | Insert a new UUIDv4 at cursor position |
| `:Messages` | Show plugin notification history (snacks notifier) |
| `:TSInstallInfo` | Show treesitter parser install status in a floating window (`✓`/`✗` per parser). Recreated — removed in the nvim-treesitter v1 rewrite. Close with `q` or `<Esc>`. |
| `:BlinkClearFrequency` | Clear blink.cmp frecency/recency cache |

---

## 17. LSP

> Available in buffers where an LSP server is attached.

| Key | Mode | Action |
|-----|------|--------|
| `gd` | n | Go to definition (snacks picker) |
| `gr` | n | Go to references (snacks picker) |
| `gI` | n | Go to implementation (snacks picker) |
| `gy` | n | Go to type definition (snacks picker) |
| `gD` | n | Go to declaration |
| `K` | n | Hover documentation |
| `gK` | n | Signature help |
| `<C-k>` | i | Signature help |
| `<leader>ca` | n, x | Code action |
| `<leader>cc` | n, x | Run codelens |
| `<leader>cC` | n | Refresh & display codelens |
| `<leader>cr` | n | Rename symbol (inc-rename, live preview) |
| `<leader>cR` | n | Rename file + update all LSP imports |
| `<leader>cA` | n | Source action |
| `<leader>gd` | n | Go to definition in **horizontal split** |
| `<leader>gD` | n | Go to definition in **vertical split** |
| `<leader>ss` | n | LSP document symbols (snacks picker) |
| `<leader>sS` | n | LSP workspace symbols (snacks picker) |
| `<leader>cm` | n | Open Mason (tool installer) |
| `<leader>lf` | n, v | Format document / range (conform or LSP) |

---

## 18. Diagnostics (keymaps)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>cd` | n | Line diagnostics (float popup) |
| `]d` / `[d` | n | Next / previous diagnostic |
| `]e` / `[e` | n | Next / previous error |
| `]w` / `[w` | n | Next / previous warning |

> See also [Diagnostic Commands](#diagnostic-commands) for `:Diag*` user commands.

---

## 19. Git — Inline Hunks (gitsigns)

> Buffer-local. Available in any file tracked by git.

| Key | Mode | Action |
|-----|------|--------|
| `]h` | n | Next hunk |
| `[h` | n | Previous hunk |
| `]H` | n | Last hunk |
| `[H` | n | First hunk |
| `<leader>ghs` | n, x | Stage hunk |
| `<leader>ghr` | n, x | Reset hunk |
| `<leader>ghS` | n | Stage entire buffer |
| `<leader>ghu` | n | Undo last stage |
| `<leader>ghR` | n | Reset entire buffer |
| `<leader>ghp` | n | Preview hunk inline |
| `<leader>ghb` | n | Blame line (full commit info) |
| `<leader>ghB` | n | Blame entire buffer (panel) |
| `<leader>ghd` | n | Diff this vs index |
| `<leader>ghD` | n | Diff this vs HEAD~ |
| `ih` | o, x | Select hunk (text object) |
| `<leader>uG` | n | Toggle git signs |

---

## 20. Git — Pickers (snacks)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>gs` | n | Git status picker (stage files from picker) |
| `<leader>gS` | n | Git stash list |
| `<leader>gb` | n | Git branches |
| `<leader>gL` | n | Git log (all commits) |
| `<leader>gll` | n | Git log (current file) |
| `<leader>gl` | n | Git log (root dir) |
| `<leader>gf` | n | Git file history |
| `<leader>Gd` | n | Git diff — staged hunks |
| `<leader>GD` | n | Git diff — vs origin |
| `<leader>gB` | n, v | Git browse (open in browser) |
| `<leader>gY` | n, v | Git browse (copy URL) |
| `<leader>gi` | n | GitHub issues (open) |
| `<leader>gI` | n | GitHub issues (all) |
| `<leader>gp` | n | GitHub pull requests (open) |
| `<leader>gP` | n | GitHub pull requests (all) |

---

## 21. Git — Neogit

> Full Magit-like panel. Covers staging, committing, push/pull, branches, tags, remotes.
> Opens as a floating window.

| Key | Mode | Action |
|-----|------|--------|
| `<leader>gn` | n | Open Neogit status (main panel) |
| `<leader>gN` | n | Open Neogit commit editor directly |

**Inside Neogit status:**

| Key | Action |
|-----|--------|
| `<Tab>` / `za` | Fold / unfold section |
| `s` | Stage file or hunk |
| `u` | Unstage file or hunk |
| `S` | Stage all in section |
| `U` | Unstage all in section |
| `<CR>` | Open file for editing |
| `cc` | Commit staged changes |
| `ca` | Amend last commit |
| `Pp` | Push |
| `Ff` | Fetch |
| `ll` | Open log view |
| `b` | Branch operations |
| `r` | Rebase |
| `t` | Tag operations |
| `M` | Remote operations |
| `?` | Show all keymaps |

---

## 22. Git — Diffview

| Key | Mode | Action |
|-----|------|--------|
| `<leader>gv` | n | Open diff for all current changes |
| `<leader>gV` | n | File history with diffs (current file) |
| `<leader>gH` | n | File history with diffs (whole repo) |
| `<leader>gX` | n | Close diffview |

---

## 23. File Explorer (neo-tree)

| Key | Mode | Action |
|-----|------|--------|
| `<F3>` | n | Toggle explorer (project root) |
| `<leader>e` | n | Toggle explorer (root dir) (LazyVim) |
| `<leader>E` | n | Toggle explorer (cwd) (LazyVim) |

**Inside neo-tree:**

| Key | Action |
|-----|--------|
| `<CR>` | Open file / expand directory |
| `w` | Open with window picker |
| `<C-x>` | Open in horizontal split (pick window) |
| `<C-v>` | Open in vertical split (pick window) |

---

## 24. Symbol Outline (aerial)

| Key | Mode | Action |
|-----|------|--------|
| `<F4>` | n | Toggle symbol outline panel |
| `<leader>cs` | n | Symbols (Trouble) |
| `<leader>cS` | n | LSP references / definitions (Trouble) |

**Inside aerial panel:**

| Key | Action |
|-----|--------|
| `<CR>` | Jump to symbol |
| `w` | Jump to symbol in picked window |
| `{` / `}` | Previous / next symbol |

---

## 25. Fuzzy Finder (snacks.picker)

| Key | Mode | Action |
|-----|------|--------|
| `<leader><Space>` | n | Find files (root dir) |
| `<leader>/` | n | Grep (root dir) |
| `<leader>:` | n | Command history |
| `<leader>,` | n | Buffers |
| `<leader>n` | n | Notification history |
| `<leader>fb` | n | Buffers |
| `<leader>ff` | n | Find files (root dir) |
| `<leader>fF` | n | Find files (cwd) |
| `<leader>fg` | n | Find git-tracked files |
| `<leader>fr` | n | Recent files |
| `<leader>fR` | n | Recent files (cwd) |
| `<leader>fc` | n | Find config files |
| `<leader>sh` | n | Help pages |
| `<leader>sM` | n | Man pages |
| `<leader>sd` | n | Diagnostics (workspace) |
| `<leader>sD` | n | Diagnostics (buffer) |
| `<leader>ss` | n | LSP document symbols |
| `<leader>sS` | n | LSP workspace symbols |
| `<leader>sg` | n | Live grep (root dir) |
| `<leader>sG` | n | Live grep (cwd) |
| `<leader>sB` | n | Grep open buffers |
| `<leader>sw` | n, x | Grep word / selection (root dir) |
| `<leader>sW` | n, x | Grep word / selection (cwd) |
| `<leader>st` | n | Todo comments |
| `<leader>sT` | n | Todo / Fix / Fixme |
| `<leader>sp` | n | Search plugin specs |
| `<leader>s"` | n | Registers |
| `<leader>?` | n | Buffer keymaps (which-key) |

---

## 26. Search & Replace (grug-far)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>sr` | n, v | Open search & replace panel |

---

## 27. Navigation (flash.nvim)

| Key | Mode | Action |
|-----|------|--------|
| `s` | n, x, o | Flash jump (label any visible position) |
| `S` | n, o, x | Flash treesitter (label treesitter nodes) |
| `r` | o | Remote flash (jump + action + return) |
| `R` | o, x | Treesitter search |
| `<C-s>` | c | Toggle flash in `/` search |
| `<C-Space>` | n, o, x | Treesitter incremental selection |

> **eyeliner.nvim** runs passively alongside flash: it continuously highlights unique characters on the current line (those reachable with a single `f`/`t` keystroke) with a distinct color, and dims non-unique ones. No extra keys required.

---

## 28. Undo Tree

| Key | Mode | Action |
|-----|------|--------|
| `<F6>` | n | Toggle undo tree panel |

**Inside undotree panel:** use `j`/`k` to navigate, `<CR>` to restore, `d` to diff.

---

## 29. Refactoring

> `<leader>r*` keys available in normal and visual mode.

| Key | Mode | Action |
|-----|------|--------|
| `<leader>rs` | n, x | Pick refactoring operation (snacks picker) |

**Available refactoring operations (via picker):**
- Extract function / variable / block
- Inline function / variable
- (Go / C / C++ / Java also prompt for return type and parameter types)

---

## 30. Text Objects

> These extend the built-in `mini.ai` text objects. Use with `v`, `d`, `c`, `y`, etc.

| Object | Inner / Outer | Description |
|--------|---------------|-------------|
| `iS` / `aS` | inner / outer | Subword (camelCase or snake_case segment) |
| `ii` / `ai` | inner / outer | Indentation block (same level) |
| `iv` / `av` | inner / outer | Value (RHS of assignment) |
| `ik` / `ak` | inner / outer | Key (LHS of assignment) |
| `iz` / `az` | inner / outer | Closed fold |
| `im` / `am` | inner / outer | Chain member (method chain element) |
| `iF` / `aF` | inner / outer | File path |
| `i#` / `a#` | inner / outer | Colour value |
| `iD` / `aD` | inner / outer | Double square brackets `[[ ]]` |
| `iN` / `aN` | inner / outer | Notebook cell |
| `!` | — | Diagnostic under cursor |
| `L` | — | URL |
| `gG` | — | Entire buffer |
| `gw` | — | All visible lines in window |
| `g;` | — | Last change |

**Built-in mini.ai objects (LazyVim):** `a`=argument, `b`=brackets, `f`=function call, `i`=indent, `t`=tag, `q`=quote, `o`=block…

---

## 31. Go Language Tools

> Buffer-local. Available only in Go (`.go`) files.

| Key | Mode | Action |
|-----|------|--------|
| `<leader>gta` | n | Add struct tags (prompts, default: `json,yaml`) |
| `<leader>gto` | n | Add tag options (prompts, default: `json=omitempty`) |
| `<leader>gtr` | n | Remove struct tags (prompts for tag names) |
| `<leader>gtx` | n | Clear all tags on struct field under cursor |
| `<leader>gI` | n | Generate interface stubs via `impl` |

> **Note:** `<leader>gI` is buffer-local and overrides the global GitHub issues picker when in a Go buffer.

---

## 32. AI — Claude Code

> Connects Neovim to the Claude Code CLI via WebSocket (MCP protocol).
> Requires the Claude Code CLI to be running.

| Key | Mode | Action |
|-----|------|--------|
| `<leader>a` | n, v | AI group label |
| `<leader>ac` | n | Toggle Claude Code panel |
| `<leader>af` | n | Focus Claude Code panel |
| `<leader>ar` | n | Resume last Claude session |
| `<leader>aC` | n | Continue last Claude session |
| `<leader>ab` | n | Add current buffer to Claude context |
| `<leader>as` | v | Send selection to Claude |
| `<leader>as` | n | Add current file to Claude (on save) |
| `<leader>aa` | n | Accept diff suggested by Claude |
| `<leader>ad` | n | Deny diff suggested by Claude |

---

## 33. AI — Avante

> Inline AI assistant (Cursor-style). Uses Anthropic API directly.
> Model: `claude-sonnet-4-6`.

| Key | Mode | Action |
|-----|------|--------|
| `<leader>A` | n, v | Avante group label |
| `<leader>Aa` | n, v | Ask Avante |
| `<leader>Ac` | n | Chat with Avante |
| `<leader>Ae` | n, v | Edit with Avante instructions |
| `<leader>Af` | n | Focus Avante panel |
| `<leader>Ah` | n | Avante chat history |
| `<leader>Am` | n | Select Avante model |
| `<leader>An` | n | New Avante chat |
| `<leader>Ap` | n | Switch Avante provider |
| `<leader>Ar` | n | Refresh Avante |
| `<leader>As` | n | Stop Avante |
| `<leader>At` | n | Toggle Avante panel |

---

## 34. UI Toggles (snacks)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>uf` | n | Toggle auto-format (buffer) |
| `<leader>uF` | n | Toggle auto-format (global) |
| `<leader>us` | n | Toggle spell checking |
| `<leader>uw` | n | Toggle word wrap |
| `<leader>ul` | n | Toggle line numbers |
| `<leader>uL` | n | Toggle relative line numbers |
| `<leader>ud` | n | Toggle diagnostics |
| `<leader>uG` | n | Toggle git signs |
| `<leader>uc` | n | Toggle conceal level |
| `<leader>uT` | n | Toggle treesitter highlight |
| `<leader>ub` | n | Toggle dark/light background |
| `<leader>uD` | n | Toggle dim mode |
| `<leader>ua` | n | Toggle animations |
| `<leader>ug` | n | Toggle indent guides |
| `<leader>uS` | n | Toggle smooth scroll |
| `<leader>uh` | n | Toggle inlay hints |
| `<leader>uZ` | n | Toggle window zoom |
| `<leader>uz` | n | Toggle zen mode |
| `<leader>ut` | n | Toggle treesitter context (sticky scroll) |
| `<leader>ui` | n | Inspect highlight at cursor |
| `<leader>uI` | n | Inspect treesitter tree |

---

## 35. Windows & Tabs (LazyVim)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>xl` | n | Toggle location list |
| `<leader>xq` | n | Toggle quickfix list |
| `[q` / `]q` | n | Previous / next quickfix item |
| `<leader>l` | n | Open Lazy (plugin manager) |
| `<leader>L` | n | LazyVim changelog |
| `<leader>K` | n | Keywordprg (language docs) |
| `<leader>Qq` | n | Quit all (`:qa`) |
| `<leader>Qa` | n | Quit all without saving (`:qa!`) |

---

## 36. Trouble (diagnostics list)

| Key | Mode | Action |
|-----|------|--------|
| `<leader>xx` | n | Workspace diagnostics (Trouble) |
| `<leader>xX` | n | Buffer diagnostics (Trouble) |
| `<leader>cs` | n | Symbols (Trouble) |
| `<leader>cS` | n | LSP references / definitions (Trouble) |
| `<leader>xL` | n | Location list (Trouble) |
| `<leader>xQ` | n | Quickfix list (Trouble) |
| `[q` / `]q` | n | Previous / next Trouble / quickfix item |

---

## 37. Todo Comments

| Key | Mode | Action |
|-----|------|--------|
| `]t` | n | Next TODO comment |
| `[t` | n | Previous TODO comment |
| `<leader>xt` | n | All TODOs (Trouble) |
| `<leader>xT` | n | TODO / FIX / FIXME (Trouble) |
| `<leader>st` | n | Search TODOs (snacks picker) |
| `<leader>sT` | n | Search TODO / FIX / FIXME (snacks picker) |

---

## 38. Formatting

| Key / Command | Mode | Action |
|---------------|------|--------|
| `<leader>lf` | n, v | Format document or range (conform → LSP fallback) |
| `:FormatJSON` | — | Pretty-print JSON via `jq` (accepts range) |
| `:FormatXML` | — | Pretty-print XML via `xmllint` (accepts range) |

**Auto-format on save** is configured per filetype via conform.nvim:

| Filetype | Formatter |
|----------|-----------|
| Python | `ruff_format`, `ruff_organize_imports` |
| JavaScript / TypeScript / HTML / CSS / SCSS / YAML / JSON | `prettier` |
| C / C++ | `clang_format` |
| Shell | `shfmt` (4-space indent) |
| Go | `gofmt` + `goimports` (via LazyVim Go extra) |

---

## 39. Keymap Conflicts Resolved

| Original Key | Was | Now | Reason |
|---|---|---|---|
| `<leader>cf` | LazyVim format | Paste from `~/.tmp/.vbuf` | Kept original vimrc paste binding |
| `<leader>lf` | _(unbound)_ | Format document/range | Moved format here |
| `<leader>gd` | snacks git diff | LSP definition (hsplit) | LSP split more useful |
| `<leader>gD` | snacks git diff (origin) | LSP definition (vsplit) | LSP split more useful |
| `<leader>Gd` | _(unbound)_ | Git diff (snacks) | Git diff moved to capital G |
| `<leader>GD` | _(unbound)_ | Git diff vs origin | Git diff moved to capital G |
| `<leader>gb` | LazyVim blame line | Git branches picker | Branches more useful on bare key |
| `<leader>gg` | Lazygit | _(removed)_ | Using neogit instead |
| `<leader>gG` | Lazygit (cwd) | _(removed)_ | Using neogit instead |
| `<leader>qq` | LazyVim quit all | `<leader>Qq` | `\q` = `:only` (close other windows) |
| `<leader>qa` | LazyVim quit force | `<leader>Qa` | Same reason |
| `<leader>Aa` | avante ask | _(moved from `\aa`)_ | `\a` prefix reserved for Claude Code |
| All `<leader>a*` avante keys | `\a*` | `\A*` | Avoid clash with claudecode `\a` prefix |
