-- Command palette (like IntelliJ "Find Action"): every described normal-mode
-- keymap (incl. buffer-local LSP/jdtls ones) plus all :commands. Enter runs it.
local function palette()
  Snacks.picker({
    title = "Actions",
    multi = {
      { source = "keymaps", modes = { "n" } },
      "commands",
    },
    -- keymaps without a description are internal/default mappings: just noise here
    transform = function(item)
      if item.source_id == 1 and not (item.item and item.item.desc and item.item.desc ~= "") then
        return false
      end
    end,
    layout = { preset = "vscode" },
    -- explicit dispatch: snacks' multi-source picker would otherwise "jump" to the definition
    confirm = function(picker, item, action)
      if item and item.source_id == 1 then
        return Snacks.picker.sources.keymaps.confirm(picker, item, action) -- run the keymap
      end
      return Snacks.picker.actions.cmd(picker, item) -- put `:Command` on the cmdline
    end,
  })
end

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>a", palette, desc = "Command Palette (all actions)" },
    },
  },
}
