-- Notes: work notes (~/notes, OneDrive) and private notes (~/private/notes, git).
-- Plain markdown/text files, [[wikilinks]] between notes, normal links for other
-- files and URLs. marksman (LSP) gives gd / gr / link completion; <CR> follows any
-- link. Keys live under <leader>n, todos are in config/todos.lua.
local M = {}

M.work = vim.fn.expand("~/notes")
M.private = vim.fn.expand("~/private/notes")

local function realpath(path)
  return vim.uv.fs_realpath(path) or path
end

local roots = { realpath(M.work), realpath(M.private) }

-- Root folder of `path` if it is a note, else nil (works for not yet saved files).
function M.root(path)
  if not path or path == "" then
    return nil
  end
  local dir = realpath(vim.fs.dirname(path))
  for _, root in ipairs(roots) do
    if dir == root or vim.startswith(dir, root .. "/") then
      return root
    end
  end
end

local function edit(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
end

-- Following links -------------------------------------------------------------

-- Opened in the system app instead of Neovim.
local EXTERNAL = {
  pdf = true, png = true, jpg = true, jpeg = true, gif = true, svg = true, webp = true,
  html = true, pptx = true, docx = true, xlsx = true, mkv = true, mp4 = true, mov = true,
}

-- Link under the cursor: target and kind ("wiki" | "md" | "url").
local function link_at_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local patterns = {
    { "%[%[(.-)%]%]", "wiki" },
    { "%[[^%]]*%]%((.-)%)", "md" },
    { "<(https?://[^>]+)>", "url" },
    { "(https?://[^%s%)%]>\"']+)", "url" },
  }
  for _, p in ipairs(patterns) do
    local init = 1
    while true do
      local s, e, target = line:find(p[1], init)
      if not s then
        break
      end
      if col >= s and col <= e then
        return target, p[2]
      end
      init = e + 1
    end
  end
end

local function jump_to_heading(heading)
  if not heading or heading == "" then
    return
  end
  heading = heading:lower()
  for i, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if l:gsub("^#+%s*", ""):lower() == heading then
      vim.api.nvim_win_set_cursor(0, { i, 0 })
      return
    end
  end
end

-- [[name]] → name.md (or name if it has an extension), next to the current note,
-- in its notes root or anywhere below it; a new note if it doesn't exist yet.
local function resolve_wiki(name, dir)
  local root = M.root(vim.api.nvim_buf_get_name(0)) or dir
  local has_ext = name:match("%.%w+$") ~= nil
  for _, base in ipairs({ dir, root }) do
    for _, candidate in ipairs({ name .. ".md", has_ext and name or nil }) do
      if candidate and vim.uv.fs_stat(base .. "/" .. candidate) then
        return base .. "/" .. candidate
      end
    end
  end
  local found = vim.fs.find(vim.fs.basename(name) .. ".md", { path = root, type = "file", limit = 1 })[1]
  return found or (dir .. "/" .. name .. (has_ext and "" or ".md"))
end

function M.follow_link()
  local target, kind = link_at_cursor()
  if not target then
    return false
  end
  if kind == "url" or target:match("^%a[%w+.-]*://") or target:match("^mailto:") then
    vim.ui.open(target)
    return true
  end

  local dir = vim.fn.expand("%:p:h")
  local path, heading
  if kind == "wiki" then
    local name = target:gsub("|.*$", "") -- [[name|alias]]
    name, heading = name:match("^([^#]*)#?(.*)$")
    if name == "" then
      jump_to_heading(heading) -- [[#heading]]
      return true
    end
    path = resolve_wiki(name, dir)
  else
    target = target:gsub("^<(.*)>$", "%1"):gsub("%%20", " ")
    path, heading = target:match("^([^#]*)#?(.*)$")
    if path == "" then
      jump_to_heading(heading)
      return true
    end
    path = vim.fn.expand(path)
    if not vim.startswith(path, "/") then
      path = dir .. "/" .. path
    end
    if not vim.uv.fs_stat(path) and vim.uv.fs_stat(path .. ".md") then
      path = path .. ".md"
    end
  end

  local ext = (path:match("%.(%w+)$") or ""):lower()
  if EXTERNAL[ext] then
    vim.ui.open(path)
  else
    if not vim.uv.fs_stat(path) then
      vim.notify("New note: " .. vim.fn.fnamemodify(path, ":~"), vim.log.levels.INFO, { title = "Notes" })
    end
    edit(path)
    jump_to_heading(heading)
  end
  return true
end

-- Quiet buffers for notes: no spell, lint, diagnostics or format-on-save.
local function setup_buffer(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local ft = vim.bo[buf].filetype
  local is_note = M.root(name) ~= nil
  if ft ~= "markdown" and not (is_note and ft == "text") then
    return
  end
  vim.keymap.set("n", "<CR>", function()
    if not M.follow_link() then
      vim.api.nvim_feedkeys(vim.keycode("<CR>"), "n", false)
    end
  end, { buffer = buf, desc = "Follow Link" })
  if is_note then
    vim.b[buf].autoformat = false
    vim.diagnostic.enable(false, { bufnr = buf })
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      vim.wo[win][0].spell = false
    end
  end
end

function M.setup()
  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { desc = desc })
  end
  local todos = require("config.todos")
  -- stylua: ignore start
  map("<leader>nn", function() edit(M.work .. "/tmp_notes.txt") end, "Tmp Notes")
  map("<leader>nt", todos.open, "Todos")
  map("<leader>na", todos.add, "Add Todo")
  map("<leader>nd", todos.done, "Mark Todo Done")
  map("<leader>nw", function() edit(M.work .. "/work-notes.md") end, "Work Notes")
  map("<leader>ni", function() edit(M.work .. "/index.md") end, "Work Notes Index")
  map("<leader>nf", function() Snacks.picker.files({ cwd = M.work, title = "Work Notes" }) end, "Find Work Note")
  map("<leader>nc", function() edit(M.private .. "/Cheatsheets.md") end, "Cheatsheets")
  map("<leader>np", function() edit(M.private .. "/index.md") end, "Private Notes Index")
  map("<leader>nP", function() Snacks.picker.files({ cwd = M.private, title = "Private Notes" }) end, "Find Private Note")
  map("<leader>ns", function() Snacks.picker.grep({ dirs = { M.work, M.private }, title = "Search Notes" }) end, "Search Notes")
  -- stylua: ignore end
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({ { "<leader>n", group = "notes" } })
  end

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("notes", { clear = true }),
    pattern = { "markdown", "text" },
    callback = function(args)
      setup_buffer(args.buf)
    end,
  })
  -- keymaps.lua loads after the first file was opened
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      setup_buffer(buf)
    end
  end
end

return M
