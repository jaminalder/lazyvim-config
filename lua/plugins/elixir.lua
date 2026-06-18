return {
  -- Import LazyVim Elixir extra for base configuration
  { import = "lazyvim.plugins.extras.lang.elixir" },

  -- Add Elixir treesitter parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "elixir",
        "heex",
        "eex",
        "surface",
      })
    end,
  },

  -- Configure LSP for Elixir
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        elixirls = {
          settings = {
            elixirLS = {
              dialyzerEnabled = true,
              fetchDeps = false,
              enableTestLenses = true,
              suggestSpecs = true,
            },
          },
        },
      },
    },
  },

  -- Ensure mason installs elixir-ls
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "elixir-ls" })
    end,
  },

  -- Add Elixir formatting support
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        elixir = { "mix" },
        heex = { "mix" },
        eex = { "mix" },
        surface = { "mix" },
      },
    },
  },

  -- Phoenix/HEEx specific enhancements
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
      },
    },
  },
}
