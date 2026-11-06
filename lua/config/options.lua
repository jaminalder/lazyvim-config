-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Leaders. Set before lazy.nvim loads so every <leader>/<localleader> mapping
-- picks them up. <localleader> drives the Conjure (Clojure REPL) and paredit
-- mappings; "ö" is a single key on a DE-CH keyboard.
vim.g.mapleader = " "
vim.g.maplocalleader = "ö"

-- Root detection picks the deepest LSP root. angularls roots at each Angular app,
-- which would shrink pickers/grep to one app instead of the whole monorepo.
vim.g.root_lsp_ignore = { "copilot", "angularls" }

-- Conjure (Clojure REPL) tweaks. Set here rather than in the plugin spec so we
-- don't clobber the `init` function defined by LazyVim's Clojure extra. Conjure
-- reads these globals when it boots, well after this file has loaded.
vim.g["conjure#log#hud#enabled"] = false -- no floating HUD; we keep the log in a vsplit instead
vim.g["conjure#log#botright"] = true -- open the log split at the far right / bottom
vim.g["conjure#highlight#enabled"] = true -- briefly highlight the form being evaluated
vim.g["conjure#eval#result_register"] = "*" -- yank last eval result to the * register
-- Eval mappings stay under <localleader>, e.g. <localleader>ee to eval a form,
-- <localleader>lv to (re)open the log in a vertical split, <localleader>lq to close it.
