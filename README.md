# Neovim config

[LazyVim](https://github.com/LazyVim/LazyVim)-based setup, mainly for Java (Maven monorepos) and
TypeScript/Angular, plus Go, Python and Clojure.

## Highlights

| Key | What |
| --- | --- |
| `<leader>a` | Command palette: all described keymaps + commands |
| `gd` / `gr` / `gI` | Definition / references / implementations (jdtls, vtsls, angularls) |
| `<leader>ss` / `<leader>sS` / `<leader>cs` | File symbols / workspace symbols / outline |
| `<leader>t…` | Tests: `r` nearest, `t` file, `u` unit, `i` integration, `T` all, `l` last, `O` surefire report |
| `<leader>r…` | Run consoles: `p` presets, `s` Spring Boot, `n` package.json script, `r` switch, `R` restart, `k`/`K` stop |
| `<leader>n…` | Notes: `n` tmp, `t` todos, `a`/`d` add/done todo, `w` work, `i`/`f` work index/find, `p`/`P` private index/find, `c` cheatsheets, `s` search |
| `<CR>` | In notes/markdown: follow `[[wikilink]]`, file link or URL (`<C-o>` back) |
| `<leader>gg` | Lazygit (delta diffs, edits open in this Neovim) |
| `<leader>gB` / `<leader>gY` | Open / copy GitLab or GitHub link for the current line |

## Layout

- `lua/config/` – options, keymaps, autocmds and the custom test runner (`testrunner.lua`),
  run consoles (`runner.lua`, presets in `run_presets.lua`), notes (`notes.lua`, `todos.lua`)
  and `:CheatsheetBuild` (the printable sheet lives in `~/private/notes/cheatsheets/vim_print_cheatsheet`).
- `lua/plugins/` – plugin specs: Java/jdtls tuning, pickers, git, palette, notes, Clojure, Oil, lint.
- `lazyvim.json` – enabled LazyVim extras; `lazy-lock.json` – pinned plugin versions.
