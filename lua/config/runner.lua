-- Run consoles: long-running processes (Spring Boot apps, package.json scripts,
-- per-repo presets) in terminal buffers named `run:<name>`. Consoles are shown in
-- a shared bottom "run window"; they are normal listed buffers otherwise.
local M = {}

---@class RunSpec
---@field name string
---@field cwd string
---@field cmd string
---@field build? {root:string, mvn:string, module:string} Maven module to package first

---@type table<string, {spec:RunSpec, buf:integer, job:integer, code?:integer, stopping?:boolean}>
M.consoles = {}
M.win = nil ---@type integer?

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Run" })
end

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function running(c)
  return c and c.job and vim.fn.jobwait({ c.job }, 0)[1] == -1
end

-- Run window ------------------------------------------------------------------

local function scroll_to_end(win)
  local buf = vim.api.nvim_win_get_buf(win)
  pcall(vim.api.nvim_win_set_cursor, win, { vim.api.nvim_buf_line_count(buf), 0 })
end

local function run_window()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    return M.win
  end
  local cur = vim.api.nvim_get_current_win()
  vim.cmd("botright split")
  M.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(M.win, math.floor(vim.o.lines * 0.3))
  vim.wo[M.win].winfixheight = true
  vim.api.nvim_set_current_win(cur)
  return M.win
end

---@param focus? boolean
function M.show(name, focus)
  local c = M.consoles[name]
  if not (c and vim.api.nvim_buf_is_valid(c.buf)) then
    return
  end
  local win = run_window()
  vim.api.nvim_win_set_buf(win, c.buf)
  scroll_to_end(win)
  if focus then
    vim.api.nvim_set_current_win(win)
  end
end

function M.toggle_window()
  if M.win and vim.api.nvim_win_is_valid(M.win) then
    vim.api.nvim_win_close(M.win, false)
    M.win = nil
    return
  end
  local last
  for name, c in pairs(M.consoles) do
    if vim.api.nvim_buf_is_valid(c.buf) and (not last or c.buf > M.consoles[last].buf) then
      last = name
    end
  end
  if not last then
    return notify("No run consoles", vim.log.levels.WARN)
  end
  M.show(last)
end

-- Consoles --------------------------------------------------------------------

local function build_cmd(build)
  return ("%s -pl %s -am package -DskipTests"):format(build.mvn, build.module)
end

function M.stop(name)
  local c = M.consoles[name]
  if running(c) then
    c.stopping = true
    vim.fn.jobstop(c.job)
    vim.fn.jobwait({ c.job }, 10000) -- so ports are free before a restart
  end
end

---@param spec RunSpec
---@param opts? {skip_build?:boolean, on_exit?:fun(code:integer)}
function M.start(spec, opts)
  opts = opts or {}
  local old = M.consoles[spec.name]
  M.stop(spec.name)

  local cmd = spec.cmd
  if spec.build and not opts.skip_build then
    cmd = ("cd %s && %s && cd %s && %s"):format(
      vim.fn.shellescape(spec.build.root),
      build_cmd(spec.build),
      vim.fn.shellescape(spec.cwd),
      spec.cmd
    )
  end

  local buf = vim.api.nvim_create_buf(true, false)
  local win = run_window()
  local job
  local function start_job()
    job = vim.fn.jobstart(cmd, {
      term = true,
      cwd = spec.cwd,
      on_exit = function(_, code)
        local c = M.consoles[spec.name]
        if c and c.buf == buf then
          c.code = code
          if not c.stopping then
            local ok = code == 0
            notify(("%s %s exited (%d)"):format(ok and "✔" or "✘", spec.name, code), ok and nil or vim.log.levels.WARN)
          end
        end
        if opts.on_exit then
          vim.schedule(function()
            opts.on_exit(code)
          end)
        end
      end,
    })
  end
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_call(win, start_job)

  -- replace the previous console buffer everywhere it is shown
  if old and vim.api.nvim_buf_is_valid(old.buf) then
    for _, w in ipairs(vim.fn.win_findbuf(old.buf)) do
      vim.api.nvim_win_set_buf(w, buf)
    end
    vim.api.nvim_buf_delete(old.buf, { force = true })
  end
  local term_name = vim.api.nvim_buf_get_name(buf)
  vim.api.nvim_buf_set_name(buf, "run:" .. spec.name)
  local leftover = vim.fn.bufnr(term_name) -- renaming keeps the old name as an unlisted buffer
  if leftover > 0 and leftover ~= buf then
    pcall(vim.api.nvim_buf_delete, leftover, { force = true })
  end
  vim.b[buf].run_console = spec.name
  M.consoles[spec.name] = { spec = spec, buf = buf, job = job }

  -- follow the output in windows where the console is not focused
  local pending = false
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      if pending then
        return
      end
      pending = true
      vim.schedule(function()
        pending = false
        for _, w in ipairs(vim.fn.win_findbuf(buf)) do
          if w ~= vim.api.nvim_get_current_win() then
            scroll_to_end(w)
          end
        end
      end)
    end,
  })
  notify("Started " .. spec.name)
end

-- Starts several consoles; Java apps share a single Maven build (concurrent
-- builds of one reactor would clash in the shared target/ folders).
---@param specs RunSpec[]
function M.start_all(specs)
  local builds, modules, build_root = {}, {}, nil
  for _, spec in ipairs(specs) do
    if spec.build then
      builds[#builds + 1] = spec
      modules[#modules + 1] = spec.build.module
      build_root = build_root or spec.build
      M.stop(spec.name) -- stop old instances before rebuilding their jars
    else
      M.start(spec)
    end
  end
  if #builds == 0 then
    return
  end
  M.start({
    name = vim.fn.fnamemodify(build_root.root, ":t") .. ":build",
    cwd = build_root.root,
    cmd = build_cmd({ mvn = build_root.mvn, module = table.concat(modules, ",") }),
  }, {
    on_exit = function(code)
      if code ~= 0 then
        return notify("Build failed, not starting " .. #builds .. " app(s)", vim.log.levels.ERROR)
      end
      for _, spec in ipairs(builds) do
        M.start(spec, { skip_build = true })
      end
    end,
  })
end

local function current_console()
  local name = vim.b.run_console
  return name and M.consoles[name] and name or nil
end

---@param prompt string
---@param fn fun(name:string)
local function with_console(prompt, fn)
  local name = current_console()
  if name then
    return fn(name)
  end
  local names = vim.tbl_keys(M.consoles)
  table.sort(names)
  if #names == 0 then
    return notify("No run consoles", vim.log.levels.WARN)
  end
  vim.ui.select(names, { prompt = prompt }, function(choice)
    if choice then
      fn(choice)
    end
  end)
end

function M.restart()
  with_console("Restart console", function(name)
    M.start(M.consoles[name].spec)
  end)
end

function M.stop_one()
  with_console("Stop console", function(name)
    M.stop(name)
    notify("Stopped " .. name)
  end)
end

function M.stop_all()
  for name in pairs(M.consoles) do
    M.stop(name)
  end
  notify("Stopped all consoles")
end

function M.pick()
  local items = {}
  for name, c in pairs(M.consoles) do
    if vim.api.nvim_buf_is_valid(c.buf) then
      local status = running(c) and "● running" or ("○ exited " .. tostring(c.code or "?"))
      items[#items + 1] = { text = name, name = name, buf = c.buf, status = status, cmd = c.spec.cmd }
    end
  end
  if #items == 0 then
    return notify("No run consoles", vim.log.levels.WARN)
  end
  table.sort(items, function(a, b)
    return a.name < b.name
  end)
  Snacks.picker({
    title = "Run Consoles",
    items = items,
    format = function(item)
      local hl = item.status:find("running") and "DiagnosticOk" or "Comment"
      return {
        { ("%-40s"):format(item.name), "SnacksPickerFile" },
        { ("%-14s"):format(item.status), hl },
        { item.cmd, "Comment" },
      }
    end,
    preview = "file",
    confirm = function(picker, item)
      picker:close()
      if item then
        M.show(item.name, true)
      end
    end,
  })
end

-- Spring Boot -------------------------------------------------------------------

-- Command to start the newest executable jar in ./target with JAVA_HOME's java.
function M.java_jar_cmd(jvm_args)
  local args = vim.tbl_map(vim.fn.shellescape, jvm_args or {})
  return ([[exec "${JAVA_HOME:+$JAVA_HOME/bin/}java" %s -jar "$(ls -t target/*.jar | grep -vE '/original-|-(plain|sources|javadoc|tests)\.jar$' | head -1)"]]):format(
    table.concat(args, " ")
  )
end

---@param root string repo root containing mvnw
---@param module string module path relative to root
---@param opts? {name?:string, jvm_args?:string[]}
---@return RunSpec
function M.spring_boot(root, module, opts)
  opts = opts or {}
  return {
    name = opts.name or vim.fn.fnamemodify(module, ":t"),
    cwd = root .. "/" .. module,
    cmd = M.java_jar_cmd(opts.jvm_args),
    build = { root = root, mvn = exists(root .. "/mvnw") and "./mvnw" or "mvn", module = module },
  }
end

function M.run_spring_boot()
  local file = vim.api.nvim_buf_get_name(0)
  local path = file ~= "" and file or vim.uv.cwd()
  local module = vim.fs.root(path, "pom.xml")
  if not module then
    return notify("No pom.xml found", vim.log.levels.WARN)
  end
  local root = vim.fs.root(path, "mvnw")
  if not root or root == module then
    -- single-module project: plain spring-boot:run
    local dir = root or module
    return M.start({
      name = vim.fn.fnamemodify(dir, ":t"),
      cwd = dir,
      cmd = (root and "./mvnw" or "mvn") .. " spring-boot:run",
    })
  end
  M.start(M.spring_boot(root, module:sub(#root + 2)))
end

-- package.json scripts ------------------------------------------------------------

local function package_manager(dir)
  for _, pm in ipairs({ { "pnpm-lock.yaml", "pnpm" }, { "yarn.lock", "yarn" }, { "bun.lock", "bun" }, { "bun.lockb", "bun" } }) do
    if vim.fs.root(dir, pm[1]) then
      return pm[2]
    end
  end
  return "npm"
end

---@param dir string folder containing package.json
---@param script string
---@return RunSpec
function M.npm_script(dir, script)
  local pm = package_manager(dir)
  -- pnpm would otherwise run `pnpm install` first when node_modules is stale; that
  -- belongs in an explicit install, not in two consoles of one workspace at once.
  local run = pm == "pnpm" and "pnpm --config.verify-deps-before-run=warn run" or (pm .. " run")
  return {
    name = vim.fn.fnamemodify(dir, ":t") .. ":" .. script,
    cwd = dir,
    cmd = run .. " " .. script,
  }
end

-- Script key under the cursor when editing a package.json "scripts" entry.
local function script_at_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  col = math.max(col, (line:find("%S") or 1) - 1) -- cursor on indentation
  local ok, node = pcall(vim.treesitter.get_node, { pos = { row - 1, col } })
  local function key(pair)
    local k = pair:field("key")[1]
    return k and vim.treesitter.get_node_text(k, 0):gsub('^"(.*)"$', "%1")
  end
  while ok and node do
    if node:type() == "pair" then
      local parent = node:parent() and node:parent():parent()
      if parent and parent:type() == "pair" and key(parent) == "scripts" then
        return key(node)
      end
    end
    node = node:parent()
  end
end

function M.run_npm_script()
  local file = vim.api.nvim_buf_get_name(0)
  if vim.fn.fnamemodify(file, ":t") == "package.json" then
    local script = script_at_cursor()
    if script then
      return M.start(M.npm_script(vim.fs.dirname(file), script))
    end
  end
  local dir = vim.fs.root(file ~= "" and file or vim.uv.cwd(), "package.json")
  if not dir then
    return notify("No package.json found", vim.log.levels.WARN)
  end
  local ok, pkg = pcall(vim.json.decode, table.concat(vim.fn.readfile(dir .. "/package.json"), "\n"))
  local scripts = ok and type(pkg) == "table" and pkg.scripts or {}
  local names = vim.tbl_keys(scripts)
  table.sort(names)
  if #names == 0 then
    return notify("No scripts in " .. dir .. "/package.json", vim.log.levels.WARN)
  end
  vim.ui.select(names, {
    prompt = vim.fn.fnamemodify(dir, ":t") .. " scripts",
    format_item = function(name)
      return ("%-20s %s"):format(name, scripts[name])
    end,
  }, function(choice)
    if choice then
      M.start(M.npm_script(dir, choice))
    end
  end)
end

-- Presets -----------------------------------------------------------------------

function M.run_preset()
  local path = vim.api.nvim_buf_get_name(0)
  local root = vim.fs.root(path ~= "" and path or vim.uv.cwd(), ".git") or vim.uv.cwd()
  local presets = {}
  for _, project in ipairs(require("config.run_presets")) do
    if project.match(root) then
      vim.list_extend(presets, project.presets(root, M))
    end
  end
  if #presets == 0 then
    return notify("No run presets for " .. root, vim.log.levels.WARN)
  end
  vim.ui.select(presets, {
    prompt = "Run preset",
    format_item = function(p)
      return p.name
    end,
  }, function(choice)
    if choice then
      M.start_all(choice.run)
    end
  end)
end

function M.setup()
  local map = function(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { desc = desc })
  end
  map("<leader>rr", M.pick, "Switch Run Console")
  map("<leader>rp", M.run_preset, "Run Preset")
  map("<leader>rs", M.run_spring_boot, "Run Spring Boot App (module)")
  map("<leader>rn", M.run_npm_script, "Run package.json Script")
  map("<leader>ro", M.toggle_window, "Toggle Run Window")
  map("<leader>rR", M.restart, "Restart Run Console")
  map("<leader>rk", M.stop_one, "Stop Run Console")
  map("<leader>rK", M.stop_all, "Stop All Run Consoles")
  local ok, wk = pcall(require, "which-key")
  if ok then
    wk.add({ { "<leader>r", group = "run" } })
  end
end

return M
