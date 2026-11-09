# Neovim cheat sheet

`␣` Space (leader) · `ö` localleader · `C-` Ctrl · *(Java)* only in Java files · `␣a` palette finds everything else

## Find & navigate

| Key | Action |
| --- | --- |
| `␣a` | Command palette (all actions) |
| `␣␣` `␣ff` | Find files (project) |
| `␣fg` | Find git files |
| `␣fr` | Recent files |
| `␣,` | Open buffers |
| `␣/` | Grep project |
| `␣sw` | Grep word / selection |
| `␣sR` | Resume last search |
| `␣sk` | Search keymaps |
| `␣?` | Keymaps of this buffer |
| `-` | Oil: parent directory |
| `␣e` | File tree (Neo-tree) |

## Code browsing

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `gr` | References / usages |
| `gI` | Implementations |
| `gy` | Type definition |
| `K` | Hover docs |
| `gai` `gao` | Incoming / outgoing calls |
| `]]` `[[` | Next / prev usage in file |
| `␣ss` | Symbols in file |
| `␣sS` | Symbols in project (go to class) |
| `␣cs` | Outline sidebar |
| `C-o` `C-i` | Jump back / forward |
| `]d` `[d` | Next / prev diagnostic |
| `␣cd` | Diagnostics of line |
| `␣xx` | Diagnostics list |

## Edit & refactor

| Key | Action |
| --- | --- |
| `␣ca` | Code action / quick fix |
| `␣cr` | Rename symbol |
| `␣cf` | Format (no format-on-save for Java/TS) |
| `␣co` | Organize imports *(Java)* |
| `␣cxv` `␣cxc` | Extract variable / constant *(Java)* |
| `␣cxm` | Extract method, visual *(Java)* |
| `␣cgs` | Go to super method *(Java)* |
| `gcc` `gc` | Comment line / selection |
| `gsa` `gsd` `gsr` | Add / delete / replace surrounding |
| `s` `S` | Flash jump / select syntax node |
| `␣uh` | Toggle inlay hints |

## Tests

| Key | Action |
| --- | --- |
| `␣tr` | Nearest test |
| `␣tt` | Test file (or tests of this class/file) |
| `␣tu` `␣ti` | Module unit / integration tests |
| `␣tT` | All tests of module / project |
| `␣tl` | Re-run last |
| `␣to` | Toggle output |
| `␣tO` | Surefire report *(Java)* |
| `␣tS` | Stop |

## Run consoles

| Key | Action |
| --- | --- |
| `␣rp` | Preset (e.g. LAR e2e stack) |
| `␣rs` | Spring Boot app of module |
| `␣rn` | package.json script (under cursor) |
| `␣rr` | Switch console |
| `␣ro` | Toggle run window |
| `␣rR` | Restart console |
| `␣rk` `␣rK` | Stop console / all |

## Git

| Key | Action |
| --- | --- |
| `␣gg` | Lazygit (`e` edit in nvim, `\|` diff view) |
| `]h` `[h` | Next / prev change |
| `␣ghp` | Preview change |
| `␣ghs` `␣ghr` | Stage / reset change |
| `␣gd` | All changes |
| `␣gs` | Changed files |
| `␣gb` | Blame line |
| `␣gf` | File history |
| `␣gl` | Git log |
| `␣gB` `␣gY` | Open / copy GitLab link |

## Windows, buffers & terminal

| Key | Action |
| --- | --- |
| `C-h/j/k/l` | Move between windows |
| `␣-` `␣\|` | Split below / right |
| `␣wd` | Close window |
| `␣wm` | Zoom window |
| `[b` `]b` | Prev / next buffer |
| `␣bb` | Alternate buffer |
| `␣bd` `␣bo` | Close buffer / all others |
| `C-/` | Terminal |
| `C-n` | Terminal → normal mode |

## Harpoon

| Key | Action |
| --- | --- |
| `␣H` | Add file |
| `␣h` | Menu |
| `␣1` … `␣5` | Jump to file 1–5 |

## Personal & misc

| Key | Action |
| --- | --- |
| `H` `L` | Line start / end |
| `'` | Jump to mark (exact column) |
| `␣k` | This cheat sheet |
| `␣l` `␣cm` | Lazy / Mason |
| `␣qq` | Quit all |
