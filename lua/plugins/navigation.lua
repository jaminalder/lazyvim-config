-- Code navigation additions on top of LazyVim's LSP keymaps
-- (gd, gr, gI, gy, <leader>ss, <leader>sS come from LazyVim).
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            -- stylua: ignore start
            { "gai", "<cmd>FzfLua lsp_incoming_calls<cr>", desc = "C[a]lls Incoming", has = "callHierarchy/incomingCalls" },
            { "gao", "<cmd>FzfLua lsp_outgoing_calls<cr>", desc = "C[a]lls Outgoing", has = "callHierarchy/outgoingCalls" },
            -- stylua: ignore end
          },
        },
      },
    },
  },
}
