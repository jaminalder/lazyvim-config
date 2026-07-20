local M = {}

local todo_path = "/Users/taastbeb/Library/CloudStorage/OneDrive-Swisscom/notes/todos.md"
local open_heading = "OPEN"
local done_heading = "DONE"
local heading_underline = "----"

local function is_todo_buffer(buf)
  return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p") == todo_path
end

local function find_heading(lines, text)
  for i, line in ipairs(lines) do
    if line == "## " .. text or (line == text and lines[i + 1] == heading_underline) then
      return i
    end
  end
end

local function is_heading_line(lines, index)
  return lines[index]:match("^##%s") or lines[index + 1] == heading_underline
end

local function ensure_sections(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local changed = false

  if #lines == 1 and lines[1] == "" then
    lines = { open_heading, heading_underline, "", done_heading, heading_underline }
    changed = true
  end

  if not find_heading(lines, open_heading) then
    if #lines > 0 then
      table.insert(lines, "")
    end
    table.insert(lines, open_heading)
    table.insert(lines, heading_underline)
    changed = true
  end

  if not find_heading(lines, done_heading) then
    table.insert(lines, "")
    table.insert(lines, done_heading)
    table.insert(lines, heading_underline)
    changed = true
  end

  if changed then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end

  return lines
end

local function section_insert_line(lines, heading)
  local heading_line = find_heading(lines, heading)
  if not heading_line then
    return #lines + 1
  end

  local insert_line = heading_line + 1
  if lines[insert_line] == heading_underline then
    insert_line = insert_line + 1
  end

  while insert_line <= #lines and lines[insert_line] ~= "" and not is_heading_line(lines, insert_line) do
    insert_line = insert_line + 1
  end

  return insert_line
end

local function setup_buffer(buf)
  if not is_todo_buffer(buf) then
    return
  end

  vim.keymap.set("n", "<leader>n", function()
    M.add_task()
  end, { buffer = buf, desc = "Add todo task" })

  vim.keymap.set("n", "<leader>x", function()
    M.complete_task()
  end, { buffer = buf, desc = "Complete todo task" })
end

function M.open()
  vim.cmd.edit(vim.fn.fnameescape(todo_path))
  ensure_sections(0)
end

function M.add_task()
  local buf = 0
  local lines = ensure_sections(buf)
  local insert_line = section_insert_line(lines, open_heading)
  local task_prefix = "□ "

  vim.api.nvim_buf_set_lines(buf, insert_line - 1, insert_line - 1, false, { task_prefix })
  vim.api.nvim_win_set_cursor(0, { insert_line, #task_prefix })
  vim.cmd.startinsert({ bang = true })
end

function M.complete_task()
  local buf = 0
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local task = line:match("^□ (.*)$")

  if not task then
    vim.notify("Current line is not an open todo task", vim.log.levels.WARN)
    return
  end

  ensure_sections(buf)
  vim.api.nvim_buf_set_lines(buf, cursor[1] - 1, cursor[1], false, {})

  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local insert_line = section_insert_line(lines, done_heading)
  vim.api.nvim_buf_set_lines(buf, insert_line - 1, insert_line - 1, false, { "✓ " .. task })
  vim.cmd.write()
end

function M.setup()
  vim.keymap.set("n", "<leader>t", function()
    M.open()
  end, { desc = "Open todos" })

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = todo_path,
    callback = function(args)
      ensure_sections(args.buf)
      setup_buffer(args.buf)
    end,
  })

  setup_buffer(0)
end

return M
