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
    "Olical/conjure",
    init = function()
      vim.g["conjure#client_on_load"] = false
    end,
    config = function()
      local function readable(path)
        return vim.fn.filereadable(path) == 1
      end

      local function trim(s)
        local trimmed = (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
        return trimmed
      end

      local function live_port(host, port)
        if not port then
          return false
        end

        local tcp = vim.uv.new_tcp()
        local done = false
        local ok = false
        local started = pcall(tcp.connect, tcp, host, port, function(err)
          ok = err == nil
          done = true
          tcp:close()
        end)
        if not started then
          tcp:close()
          return false
        end
        vim.wait(250, function()
          return done
        end, 10)
        if not done then
          tcp:close()
        end
        return ok
      end

      local function port_file()
        local path = vim.fs.find({ ".nrepl-port", ".shadow-cljs/nrepl.port" }, {
          upward = true,
          path = vim.fn.expand("%:p:h"),
        })[1]
        if path and readable(path) then
          return path
        end
      end

      local function connect_live_port_or_start_repl()
        local port_path = port_file()
        local port = port_path and tonumber(trim(table.concat(vim.fn.readfile(port_path), "")))
        local action = require("conjure.client.clojure.nrepl.action")
        local auto_repl = require("conjure.client.clojure.nrepl.auto-repl")

        if live_port("127.0.0.1", port) then
          return action["connect-port-file"]()
        end

        if port_path then
          vim.notify("Conjure: stale nREPL port file, starting auto REPL", vim.log.levels.INFO)
        end
        return auto_repl["upsert-auto-repl-proc"]()
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("clojure_conjure_live_or_auto_repl", { clear = true }),
        pattern = { "clojure", "clojurescript", "clojurec" },
        callback = function()
          vim.schedule(connect_live_port_or_start_repl)
        end,
      })
    end,
  },
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
