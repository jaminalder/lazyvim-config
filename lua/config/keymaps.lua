-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "H", "^", { noremap = true, silent = true })
vim.keymap.set("o", "H", "^", { noremap = true, silent = true })
vim.keymap.set("v", "H", "^", { noremap = true, silent = true })
vim.keymap.set("n", "L", "$", { noremap = true, silent = true })
vim.keymap.set("o", "L", "$", { noremap = true, silent = true })
vim.keymap.set("v", "L", "$", { noremap = true, silent = true })

vim.keymap.set("n", "'", "`", { noremap = true, silent = true })
vim.keymap.set("v", "'", "`", { noremap = true, silent = true })

-- vim.keymap.set("n", "<leader>h", ":bprev<CR>", { silent = true, desc = "Jump to previous buffer" })
-- vim.keymap.set("n", "<leader>l", ":bnext<CR>", { silent = true, desc = "Jump to next buffer" })

vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
