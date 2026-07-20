-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Open the Conjure REPL log in a vertical split only when code is evaluated,
-- not just when a Clojure file is opened. Conjure fires the `User ConjureEval`
-- event on every eval; we open the log split (to the right) on the first eval
-- and keep focus in the source window. The visibility check stops further evals
-- from re-splitting once the log is already showing.
local function open_conjure_log()
  -- If the log is already visible in this tab, leave it alone.
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if bufname:match("conjure%-log%-") then
      return
    end
  end
  local ok, log = pcall(require, "conjure.log")
  if ok and log.vsplit then
    log.vsplit()
    vim.cmd("wincmd p") -- return focus to the source buffer
  end
end

vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("conjure_auto_log", { clear = true }),
  pattern = "ConjureEval",
  callback = function()
    vim.schedule(open_conjure_log)
  end,
})

local function disable_text_completion()
  vim.b.completion = false
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("disable_text_completion", { clear = true }),
  pattern = { "markdown", "text" },
  callback = disable_text_completion,
})

if vim.tbl_contains({ "markdown", "text" }, vim.bo.filetype) then
  disable_text_completion()
end
