return {
  "jellydn/hurl.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- Optional, for markdown rendering with render-markdown.nvim
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown" },
      },
      ft = { "markdown" },
    },
  },
  ft = "hurl",
  opts = {
    -- Show debugging info
    debug = false,
    -- Show notification on run
    show_notification = false,
    -- Show response in popup or split
    mode = "split",
    -- Default formatter
    formatters = {
      json = { "jq" }, -- Make sure you have install jq in your system, e.g: brew install jq
      html = {
        "prettier", -- Make sure you have install prettier in your system, e.g: npm install -g prettier
        "--parser",
        "html",
      },
      xml = {
        "tidy", -- Make sure you have installed tidy in your system, e.g: brew install tidy-html5
        "-xml",
        "-i",
        "-q",
      },
    },
    -- Default mappings for the response popup or split views
    mappings = {
      close = "q", -- Close the response popup or split view
      next_panel = "<C-n>", -- Move to the next response popup window
      prev_panel = "<C-p>", -- Move to the previous response popup window
    },
  },
  -- Hurl keys live in a <localleader>h group and only exist in .hurl buffers.
  keys = {
    { "<localleader>h", "", desc = "+hurl", ft = "hurl" },
    { "<localleader>hr", "<cmd>HurlRunnerAt<CR>", desc = "Run Api request", ft = "hurl" },
    { "<localleader>hA", "<cmd>HurlRunner<CR>", desc = "Run All requests", ft = "hurl" },
    { "<localleader>he", "<cmd>HurlRunnerToEntry<CR>", desc = "Run Api request to entry", ft = "hurl" },
    { "<localleader>hE", "<cmd>HurlRunnerToEnd<CR>", desc = "Run Api request from current entry to end", ft = "hurl" },
    { "<localleader>hm", "<cmd>HurlToggleMode<CR>", desc = "Hurl Toggle Mode", ft = "hurl" },
    { "<localleader>hv", "<cmd>HurlVerbose<CR>", desc = "Run Api in verbose mode", ft = "hurl" },
    { "<localleader>hV", "<cmd>HurlVeryVerbose<CR>", desc = "Run Api in very verbose mode", ft = "hurl" },
    -- Run the selected Hurl requests
    { "<localleader>hr", ":HurlRunner<CR>", desc = "Hurl Runner", mode = "v", ft = "hurl" },
  },
}
