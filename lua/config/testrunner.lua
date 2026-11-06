-- Minimal test runner for Maven (JUnit) and Angular (jest via `ng test`).
-- Commands follow the idm repo conventions (AGENTS.md) and run in a bottom
-- terminal split; a notification reports pass/fail when the run finishes.
local M = {}

M.term = nil ---@type snacks.win?
M.last = nil ---@type {cmd:string, cwd:string, title:string}?

-- Helpers ------------------------------------------------------------------

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Tests" })
end

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function rel(path, root)
  return path:sub(#root + 2)
end

local function node_text(node, buf)
  return vim.treesitter.get_node_text(node, buf)
end

local function cursor_node(buf, lang)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
  if not ok or not parser then
    return nil
  end
  parser:parse()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  -- Start at the first non-blank character so a cursor on indentation still
  -- resolves to the enclosing statement instead of the surrounding block.
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  col = math.max(col, (line:find("%S") or 1) - 1)
  return vim.treesitter.get_node({ bufnr = buf, pos = { row - 1, col }, lang = lang, ignore_injections = true })
end

-- Runner -------------------------------------------------------------------

function M.stop()
  local term = M.term
  M.term = nil -- before closing, so its TermClose handler stays silent
  if term and term:buf_valid() then
    local job = vim.b[term.buf].terminal_job_id
    if job then
      pcall(vim.fn.jobstop, job)
    end
    term:close()
  end
end

---@param job {cmd:string, cwd:string, title:string}
function M.run(job)
  M.stop()
  M.last = job
  vim.cmd("silent! wall") -- Maven and jest read from disk
  notify("Running " .. job.title)
  local term = Snacks.terminal.open(job.cmd, {
    cwd = job.cwd,
    interactive = false,
    win = {
      position = "bottom",
      height = 0.35,
      enter = false,
      wo = { winbar = " " .. job.title .. "  (" .. job.cmd .. ")" },
    },
  })
  M.term = term
  -- Keep the (unfocused) output window scrolled to the newest line.
  local pending = false
  vim.api.nvim_buf_attach(term.buf, false, {
    on_lines = function()
      if pending then
        return
      end
      pending = true
      vim.schedule(function()
        pending = false
        local win = term.win
        if term:buf_valid() and win and vim.api.nvim_win_is_valid(win) and vim.api.nvim_get_current_win() ~= win then
          vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(term.buf), 0 })
        end
      end)
    end,
  })
  term:on("TermClose", function()
    if M.term ~= term then
      return -- stopped or replaced by a newer run
    end
    local code = vim.v.event.status
    if code == 0 then
      notify("✔ Passed: " .. job.title)
    else
      notify("✘ Failed: " .. job.title .. " (exit " .. code .. ")", vim.log.levels.ERROR)
    end
  end, { buf = true })
end

function M.run_last()
  if not M.last then
    return notify("No test run yet", vim.log.levels.WARN)
  end
  M.run(M.last)
end

function M.toggle_output()
  if M.term and M.term:buf_valid() then
    M.term:toggle()
  else
    notify("No test output", vim.log.levels.WARN)
  end
end

-- Maven / JUnit -------------------------------------------------------------

local TEST_ANNOTATIONS = { "Test", "ParameterizedTest", "RepeatedTest", "TestFactory", "TestTemplate" }

---@return {root:string, mvn:string, module:string, module_rel?:string}?
local function maven(file)
  local module = vim.fs.root(file, "pom.xml")
  if not module then
    return nil
  end
  local root = vim.fs.root(file, "mvnw")
  local mvn = "./mvnw"
  if not root then
    -- no wrapper: use the top-most directory of the pom.xml chain
    mvn, root = "mvn", module
    for dir in vim.fs.parents(module) do
      if not exists(dir .. "/pom.xml") then
        break
      end
      root = dir
    end
  end
  return { root = root, mvn = mvn, module = module, module_rel = module ~= root and rel(module, root) or nil }
end

-- Base package directory of a module (e.g. com/swisscom/loginaccountservices),
-- used to keep `-Dtest` patterns from matching tests of upstream (-am) modules.
local function base_package(module)
  for _, src in ipairs({ "/src/main/java", "/src/test/java" }) do
    local dir, parts = module .. src, {}
    if vim.fn.isdirectory(dir) == 1 then
      while true do
        local subdirs, has_java = {}, false
        for name, kind in vim.fs.dir(dir) do
          if kind == "directory" then
            subdirs[#subdirs + 1] = name
          elseif name:match("%.java$") then
            has_java = true
          end
        end
        if #subdirs ~= 1 or has_java then
          break
        end
        dir = dir .. "/" .. subdirs[1]
        parts[#parts + 1] = subdirs[1]
      end
      if #parts > 0 then
        return table.concat(parts, "/")
      end
    end
  end
end

local function maven_job(info, pattern, title)
  local cmd = { info.mvn }
  if info.module_rel then
    vim.list_extend(cmd, { "-pl", info.module_rel, "-am" })
  end
  if pattern then
    cmd[#cmd + 1] = "-Dtest=" .. vim.fn.shellescape(pattern)
  end
  vim.list_extend(cmd, { "-DfailIfNoTests=false", "-Dsurefire.failIfNoSpecifiedTests=false", "test" })
  return { cmd = table.concat(cmd, " "), cwd = info.root, title = title }
end

-- Enclosing test method and class chain at the cursor ("Outer$Inner", "method").
local function java_nearest(buf)
  local node = cursor_node(buf, "java")
  local method, classes = nil, {}
  while node do
    local kind = node:type()
    if kind == "method_declaration" and not method and #classes == 0 then
      for child in node:iter_children() do
        if child:type() == "modifiers" then
          local mods = node_text(child, buf)
          for _, a in ipairs(TEST_ANNOTATIONS) do
            if mods:find("@" .. a .. "%f[^%w_]") then
              method = node_text(node:field("name")[1], buf)
            end
          end
        end
      end
    elseif kind == "class_declaration" or kind == "record_declaration" then
      table.insert(classes, 1, node_text(node:field("name")[1], buf))
    end
    node = node:parent()
  end
  if #classes > 0 then
    return table.concat(classes, "$"), method
  end
end

local function java_job(scope)
  local file = vim.api.nvim_buf_get_name(0)
  local info = maven(file)
  if not info then
    return notify("No pom.xml found for " .. file, vim.log.levels.WARN)
  end
  local class = vim.fn.fnamemodify(file, ":t:r")
  local module_name = vim.fn.fnamemodify(info.module, ":t")

  if scope == "nearest" or scope == "file" then
    if not file:find("/src/test/", 1, true) then
      -- production class: run its unit and integration test
      local pattern = class .. "Test, " .. class .. "IntegrationTest"
      return maven_job(info, pattern, "tests for " .. class)
    end
    if scope == "nearest" then
      local cls, method = java_nearest(0)
      if cls then
        local pattern = method and (cls .. "#" .. method) or cls
        return maven_job(info, pattern, pattern)
      end
    end
    return maven_job(info, class, class)
  end

  local base = base_package(info.module)
  local all = base and (base .. "/**/*") or "*"
  if scope == "unit" then
    return maven_job(info, all .. ", !**/*IntegrationTest*", module_name .. " unit tests")
  elseif scope == "integration" then
    return maven_job(info, (base and (base .. "/**/") or "") .. "*IntegrationTest", module_name .. " integration tests")
  else
    return maven_job(info, base and all or nil, module_name .. " all tests")
  end
end

-- Surefire report (failures + stack traces) and captured output of the current class.
function M.open_report()
  local file = vim.api.nvim_buf_get_name(0)
  local info = maven(file)
  if not info or vim.bo.filetype ~= "java" then
    return notify("Not a Java file in a Maven module", vim.log.levels.WARN)
  end
  local pkg
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 50, false)) do
    pkg = pkg or line:match("^package%s+([%w_.]+)")
  end
  local fqcn = (pkg and (pkg .. ".") or "") .. vim.fn.fnamemodify(file, ":t:r")
  local found = false
  for _, suffix in ipairs({ ".txt", "-output.txt" }) do
    local report = info.module .. "/target/test-reports/" .. fqcn .. suffix
    if exists(report) then
      vim.cmd((found and "vsplit " or "split ") .. vim.fn.fnameescape(report))
      found = true
    end
  end
  if not found then
    notify("No surefire report for " .. fqcn .. " yet", vim.log.levels.WARN)
  end
end

-- Angular / jest --------------------------------------------------------------

local TEST_FNS = { describe = "group", fdescribe = "group", xdescribe = "group", it = "test", fit = "test", xit = "test", test = "test" }

-- Converts a jest title into a regex: literal parts escaped, dynamic parts as `.*`.
local function title_regex(node, buf, each)
  local kind = node and node:type()
  local raw
  if kind == "string" then
    raw = node_text(node, buf):sub(2, -2)
  elseif kind == "template_string" then
    raw = node_text(node, buf):sub(2, -2):gsub("%${.-}", "\1")
  elseif kind == "member_expression" and node_text(node:field("property")[1], buf) == "name" then
    raw = node_text(node:field("object")[1], buf) -- describe(MyComponent.name, ...)
  else
    return ".*"
  end
  if each then
    raw = raw:gsub("%%[sdifjoOp#]", "\1"):gsub("%$[%w_.]+", "\1")
  end
  raw = raw:gsub("[%^%$%.%|%?%*%+%(%)%[%]{}\\/]", "\\%0")
  return (raw:gsub("\1", ".*"))
end

-- Test name pattern for the describe/it blocks around the cursor.
local function jest_nearest(buf)
  local node = cursor_node(buf, vim.treesitter.language.get_lang(vim.bo[buf].filetype) or "typescript")
  local titles, innermost = {}, nil
  while node do
    if node:type() == "call_expression" then
      local fn = node:field("function")[1]
      local name, each
      if fn:type() == "identifier" then
        name = node_text(fn, buf)
      elseif fn:type() == "member_expression" then -- it.only(...), describe.skip(...)
        if node_text(fn:field("property")[1], buf) ~= "each" then -- it.each([...]) is the table, not the test
          name = node_text(fn:field("object")[1], buf)
        end
      elseif fn:type() == "call_expression" then -- it.each([...])('title', ...)
        local inner = fn:field("function")[1]
        if inner:type() == "member_expression" and node_text(inner:field("property")[1], buf) == "each" then
          name, each = node_text(inner:field("object")[1], buf), true
        end
      end
      if name and TEST_FNS[name] then
        local args = node:field("arguments")[1]
        table.insert(titles, 1, title_regex(args and args:named_child(0), buf, each))
        innermost = innermost or TEST_FNS[name]
      end
    end
    node = node:parent()
  end
  if #titles > 0 then
    return "^" .. table.concat(titles, " ") .. (innermost == "test" and "$" or " ")
  end
end

local function angular_job(scope)
  local file = vim.api.nvim_buf_get_name(0)
  local project = vim.fs.root(file, "angular.json")
  if not project then
    return notify("No angular.json found for " .. file, vim.log.levels.WARN)
  end
  local name = vim.fn.fnamemodify(project, ":t")
  local path = rel(file, project)

  if scope == "integration" then
    return notify("Angular has no integration test target here (Cypress runs separately)", vim.log.levels.WARN)
  elseif scope == "unit" or scope == "all" then
    return { cmd = "npx ng test", cwd = project, title = name .. " all tests" }
  end

  local cmd = { "npx ng test" }
  local title
  if not file:match("%.spec%.[jt]s$") then
    cmd[#cmd + 1] = "--find-related-tests=" .. vim.fn.shellescape(path)
    title = "specs related to " .. vim.fn.fnamemodify(file, ":t")
  else
    cmd[#cmd + 1] = "--test-match=" .. vim.fn.shellescape("**/" .. path)
    title = vim.fn.fnamemodify(file, ":t")
    local pattern = scope == "nearest" and jest_nearest(0)
    if pattern then
      cmd[#cmd + 1] = "--test-name-pattern=" .. vim.fn.shellescape(pattern)
      title = title .. " › " .. pattern
    end
  end
  cmd[#cmd + 1] = "--coverage=false"
  return { cmd = table.concat(cmd, " "), cwd = project, title = title }
end

-- Dispatch --------------------------------------------------------------------

local WEB_FTS = { typescript = true, javascript = true, htmlangular = true, html = true, scss = true }

---@param scope "nearest"|"file"|"unit"|"integration"|"all"
function M.test(scope)
  local file = vim.api.nvim_buf_get_name(0)
  local ft = vim.bo.filetype
  local mod, ng = vim.fs.root(file, "pom.xml"), vim.fs.root(file, "angular.json")
  local runner
  if ft == "java" then
    runner = java_job
  elseif WEB_FTS[ft] and ng then
    runner = angular_job
  elseif scope ~= "nearest" and scope ~= "file" and (mod or ng) then
    -- any other file (pom.xml, yaml, ...): use the closest Maven module or Angular project
    runner = (ng and (not mod or #ng > #mod)) and angular_job or java_job
  end
  if not runner then
    return notify("No Java test or Angular spec for this buffer", vim.log.levels.WARN)
  end
  local job = runner(scope)
  if job then
    M.run(job)
  end
end

function M.setup()
  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { desc = desc })
  end
  -- stylua: ignore start
  map("<leader>tr", function() M.test("nearest") end, "Run Nearest Test")
  map("<leader>tt", function() M.test("file") end, "Run Test File")
  map("<leader>tu", function() M.test("unit") end, "Run Unit Tests (module)")
  map("<leader>ti", function() M.test("integration") end, "Run Integration Tests (module)")
  map("<leader>tT", function() M.test("all") end, "Run All Tests (module)")
  map("<leader>tl", M.run_last, "Run Last Test")
  map("<leader>to", M.toggle_output, "Toggle Test Output")
  map("<leader>tO", M.open_report, "Open Surefire Report")
  map("<leader>tS", M.stop, "Stop Tests")
  -- stylua: ignore end
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({ { "<leader>t", group = "test" } })
  end
end

return M
