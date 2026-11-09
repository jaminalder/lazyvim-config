-- Plugin tweaks for the notes setup (see config/notes.lua).
local function in_notes(path)
  return require("config.notes").root(path) ~= nil
end

return {
  -- <leader>n is the notes prefix; notification history moves to <leader>sn
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>n", false },
      { "<leader>sn", function() Snacks.picker.notifications() end, desc = "Notification History" },
    },
  },
  -- markdown: completion only from marksman (links) and paths, no word suggestions
  {
    "saghen/blink.cmp",
    optional = true,
    opts = {
      sources = {
        per_filetype = {
          markdown = { "lsp", "path" },
        },
      },
    },
  },
  -- no markdownlint in notes (code repos / READMEs keep it)
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters = {
        ["markdownlint-cli2"] = {
          condition = function(ctx)
            return not in_notes(ctx.filename)
          end,
        },
      },
    },
  },
}
