-- Cheat sheet: <leader>k shows cheatsheet/cheatsheet.md in a float,
-- :CheatsheetBuild regenerates cheatsheet.pdf (see cheatsheet/build.sh) and opens it.
local M = {}

local dir = vim.fn.stdpath("config") .. "/cheatsheet"

function M.open()
  Snacks.win({
    file = dir .. "/cheatsheet.md",
    width = 0.85,
    height = 0.9,
    border = "rounded",
    title = " Cheat sheet  (q to close) ",
    title_pos = "center",
    bo = { modifiable = false, readonly = true },
    wo = { wrap = false, conceallevel = 2 },
  })
end

function M.build()
  vim.notify("Building cheat sheet PDF…", vim.log.levels.INFO, { title = "Cheat sheet" })
  vim.system({ dir .. "/build.sh" }, { text = true }, function(res)
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
  vim.keymap.set("n", "<leader>k", M.open, { desc = "Cheat Sheet" })
  vim.api.nvim_create_user_command("CheatsheetBuild", M.build, { desc = "Build the cheat sheet PDF and open it" })
end

return M
