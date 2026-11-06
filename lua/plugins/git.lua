-- Git: lazygit (<leader>gg) and pickers come from LazyVim/Snacks; this adds
-- "open in browser" support for the self-hosted GitLab.
local gitlab = {
  branch = "/-/tree/{branch}",
  file = "/-/blob/{branch}/{file}#L{line_start}-{line_end}",
  permalink = "/-/blob/{commit}/{file}#L{line_start}-{line_end}",
  commit = "/-/commit/{commit}",
}

return {
  {
    "folke/snacks.nvim",
    opts = {
      gitbrowse = {
        url_patterns = {
          ["code%.swisscom%.com"] = gitlab,
        },
      },
    },
  },
}
