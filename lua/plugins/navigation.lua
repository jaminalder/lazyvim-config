-- Picker display for deep Java packages: "File.java module/…/last/packages:line:col text".
-- The path is shortened in the middle, so the file name, module and line number stay
-- visible. The picker itself is selected in options.lua (vim.g.lazyvim_picker).
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        formatters = { file = { filename_first = true, min_width = 80 } },
      },
    },
  },
  -- Only applies if switching back to fzf-lua.
  {
    "ibhagwan/fzf-lua",
    optional = true,
    opts = {
      defaults = { formatter = "path.filename_first" },
    },
  },
}
