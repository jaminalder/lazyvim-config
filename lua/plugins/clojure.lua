return {
  -- Base Clojure support from LazyVim:
  -- Conjure (interactive nREPL eval), nvim-paredit, clojure treesitter, baleia
  -- (log colorizing). Already enabled via lazyvim.json, imported here so this
  -- file is the single source of truth for the Clojure setup.
  { import = "lazyvim.plugins.extras.lang.clojure" },

  -- Treesitter parser for Clojure (extend, don't overwrite).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "clojure" })
    end,
  },

  -- clojure-lsp: completion, go-to-definition, references, refactoring,
  -- formatting and clj-kondo diagnostics (clj-kondo is bundled with it).
  -- Installed via Homebrew (`brew install clojure-lsp/brew/clojure-lsp-native`)
  -- and picked up from PATH, so we tell LazyVim not to manage it through Mason.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clojure_lsp = {
          mason = false,
        },
      },
    },
  },

  -- Rainbow parentheses — practically essential for reading nested Lisp forms.
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "LazyFile", "VeryLazy" },
    config = function()
      require("rainbow-delimiters.setup").setup({})
    end,
  },

  -- Structural editing of s-expressions. Pulled in by the extra; tuned here.
  -- Default keymaps live under <localleader> (e.g. <localleader>>) for slurp/
  -- barf, drag, raise, splice, wrap, etc.
  {
    "julienvincent/nvim-paredit",
    opts = {
      use_default_keys = true,
      indent = {
        enabled = true,
      },
    },
  },

  -- REPL-aware completion from Conjure, bridged into blink.cmp (this config's
  -- completion engine) via blink.compat + cmp-conjure.
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = {
      "saghen/blink.compat",
      "PaterJason/cmp-conjure",
    },
    opts = {
      sources = {
        default = { "conjure" },
        providers = {
          conjure = {
            name = "conjure",
            module = "blink.compat.source",
            score_offset = 100,
          },
        },
      },
    },
  },
}
