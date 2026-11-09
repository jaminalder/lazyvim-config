-- One todo list: ~/notes/todos.md with sections OPEN / WAITING / DONE
-- ("Title" + "----" underline or "## Title"); items are "□ task" and "✓ task".
local M = {}

M.path = vim.fn.expand("~/notes/todos.md")

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Todos" })
end

local function find_heading(lines, text)
  for i, line in ipairs(lines) do
    if line == "## " .. text or (line == text and (lines[i + 1] or ""):match("^%-%-%-+$")) then
      return i
    end
  end
end

local function is_heading(lines, i)
  local l, next_line = lines[i] or "", lines[i + 1] or ""
  return l:match("^##?%s") ~= nil or (l ~= "" and next_line:match("^[-=][-=][-=]+$") ~= nil)
end

-- 0-based index after the last item of a section (before the blank line ending it).
local function section_end(lines, heading)
  local i = find_heading(lines, heading)
  if not i then
    return nil
  end
  if (lines[i + 1] or ""):match("^%-%-%-+$") then
    i = i + 1
  end
  while lines[i + 1] == "" do -- skip blank lines right below the heading
    i = i + 1
  end
  while lines[i + 1] and lines[i + 1] ~= "" and not is_heading(lines, i + 1) do
    i = i + 1
  end
  return i
end

local function insert_item(buf, heading, item)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local at = section_end(lines, heading)
  if not at then
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "", heading, ("-"):rep(#heading), "", item })
    return
  end
  -- empty section: keep a blank line between the new item and the next heading
  local add = is_heading(lines, at + 1) and { item, "" } or { item }
  vim.api.nvim_buf_set_lines(buf, at, at, false, add)
end

local function save(buf)
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent write")
  end)
end

function M.open()
  vim.cmd.edit(vim.fn.fnameescape(M.path))
end

-- Quick capture from anywhere: appended to OPEN and saved, the current buffer stays.
function M.add()
  vim.ui.input({ prompt = "New todo: " }, function(text)
    text = text and vim.trim(text) or ""
    if text == "" then
      return
    end
    local buf = vim.fn.bufadd(M.path)
    vim.fn.bufload(buf)
    insert_item(buf, "OPEN", "□ " .. text)
    save(buf)
    notify("Added: " .. text)
  end)
end

-- In todos.md: move the open item under the cursor to DONE.
function M.done()
  local function real(p)
    return vim.uv.fs_realpath(p) or p
  end
  if real(vim.api.nvim_buf_get_name(0)) ~= real(M.path) then
    return notify("Open the todos (<leader>nt) to mark items done", vim.log.levels.WARN)
  end
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local task = vim.api.nvim_get_current_line():match("^□%s*(.*)$")
  if not task then
    return notify("Not an open todo (□ …)", vim.log.levels.WARN)
  end
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, {})
  insert_item(0, "DONE", "✓ " .. task)
  save(0)
  local last = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_win_set_cursor(0, { math.min(row, last), 0 })
end

return M
