-- :CheatsheetBuild rebuilds the printable Neovim cheat sheet (kept in the private
-- notes, see vim_print_cheatsheet/build.sh) and opens the PDF.
local M = {}

local build = vim.fn.expand("~/private/notes/cheatsheets/vim_print_cheatsheet/build.sh")

function M.build()
  vim.notify("Building cheat sheet PDF…", vim.log.levels.INFO, { title = "Cheat sheet" })
  vim.system({ build }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return vim.notify("Build failed:\n" .. (res.stderr or ""), vim.log.levels.ERROR, { title = "Cheat sheet" })
      end
      local pdf = vim.trim(res.stdout)
      vim.notify("Built " .. pdf, vim.log.levels.INFO, { title = "Cheat sheet" })
      vim.ui.open(pdf)
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("CheatsheetBuild", M.build, { desc = "Build the printable cheat sheet PDF and open it" })
end

return M
