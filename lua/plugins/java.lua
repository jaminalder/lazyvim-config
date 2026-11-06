-- Java via nvim-jdtls (LazyVim `lang.java` extra), tuned for big multi-module
-- Maven repos like ~/dev/idm. Goal: reliable gd / gr / gI / workspace symbols,
-- including navigation into library sources. No debugger / test runner.

-- Map of major version -> JDK home, from sdkman and the macOS JDK locations.
local function find_jdks()
  local home = vim.env.HOME
  local candidates = {}
  for _, pattern in ipairs({
    home .. "/.sdkman/candidates/java/*",
    home .. "/Library/Java/JavaVirtualMachines/*/Contents/Home",
    "/Library/Java/JavaVirtualMachines/*/Contents/Home",
    "/opt/homebrew/opt/openjdk*/libexec/openjdk.jdk/Contents/Home",
  }) do
    vim.list_extend(candidates, vim.fn.glob(pattern, false, true))
  end
  if vim.env.JAVA_HOME then
    table.insert(candidates, 1, vim.env.JAVA_HOME) -- JAVA_HOME wins for its version
  end

  local jdks = {} ---@type table<number, string>
  for _, dir in ipairs(candidates) do
    local real = vim.uv.fs_realpath(dir)
    local release = real and real .. "/release"
    if release and vim.uv.fs_stat(release) then
      for _, line in ipairs(vim.fn.readfile(release)) do
        local version = line:match('^JAVA_VERSION="([^"]+)"')
        local major = version and tonumber(version:match("^1%.(%d+)") or version:match("^(%d+)"))
        if major and not jdks[major] then
          jdks[major] = real
        end
      end
    end
  end
  return jdks
end

-- jdtls itself must run on a recent JDK (1.63+ needs Java 25), independent of
-- the project's JDK (configured via runtimes below). Use the newest JDK found.
local function jdtls_java(jdks)
  local majors = vim.tbl_keys(jdks)
  table.sort(majors)
  local newest = majors[#majors]
  return newest and jdks[newest] .. "/bin/java" or nil
end

-- Use the newest Lombok from ~/.m2 (matches what Maven compiles with); the jar
-- bundled with Mason's jdtls lags behind and misses newer lombok.config keys.
local function lombok_jar()
  local jars = vim.fn.glob(vim.env.HOME .. "/.m2/repository/org/projectlombok/lombok/*/lombok-*[0-9].jar", false, true)
  table.sort(jars, function(a, b)
    local va = vim.version.parse(a:match("lombok%-([%d%.]+)%.jar$") or "0")
    local vb = vim.version.parse(b:match("lombok%-([%d%.]+)%.jar$") or "0")
    return va and vb and vim.version.lt(va, vb) or false
  end)
  local mason = vim.fn.expand("$MASON/share/jdtls/lombok.jar")
  return jars[#jars] or (vim.uv.fs_stat(mason) and mason) or nil
end

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local jdks = find_jdks()

      local cmd = { vim.fn.exepath("jdtls") }
      local java = jdtls_java(jdks)
      if java then
        table.insert(cmd, "--java-executable=" .. java)
      end
      local lombok = lombok_jar()
      if lombok then
        table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok)
      end
      -- Same JVM tuning as vscode-java; jdtls defaults to only -Xms1G.
      for _, arg in ipairs({
        "-Xmx6G",
        "-XX:+UseParallelGC",
        "-XX:GCTimeRatio=4",
        "-XX:AdaptiveSizePolicyWeight=90",
        "-Dsun.zip.disableMemoryMapping=true",
      }) do
        table.insert(cmd, "--jvm-arg=" .. arg)
      end
      opts.cmd = cmd

      local runtimes = {}
      local names = { [8] = "JavaSE-1.8", [11] = "JavaSE-11", [17] = "JavaSE-17", [21] = "JavaSE-21", [25] = "JavaSE-25" }
      for major, path in pairs(jdks) do
        if names[major] then
          table.insert(runtimes, { name = names[major], path = path, default = major == 21 or nil })
        end
      end

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          configuration = {
            runtimes = runtimes,
            updateBuildConfiguration = "automatic", -- re-import when a pom.xml changes
          },
          import = {
            gradle = { enabled = false }, -- Maven only; avoids Gradle version lookups on startup
            maven = { enabled = true },
            exclusions = {
              "**/node_modules/**",
              "**/.metadata/**",
              "**/archetype-resources/**",
              "**/META-INF/maven/**",
              "**/target/**",
            },
          },
          maxConcurrentBuilds = 4,
          -- gd into library classes: download sources, fall back to decompiling.
          maven = { downloadSources = true },
          eclipse = { downloadSources = true },
          contentProvider = { preferred = "fernflower" },
          references = { includeDecompiledSources = true },
          symbols = { includeSourceMethodDeclarations = true },
          -- Never collapse imports into `*` when organizing imports.
          sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
          completion = {
            favoriteStaticMembers = {
              "org.assertj.core.api.Assertions.*",
              "org.junit.jupiter.api.Assertions.*",
              "org.mockito.Mockito.*",
              "org.mockito.ArgumentMatchers.*",
              "org.hamcrest.Matchers.*",
            },
          },
        },
      })
      return opts
    end,
    init = function()
      -- jdtls asks the client to reload debug/test bundles, which we don't use.
      vim.lsp.commands["_java.reloadBundles.command"] = function()
        return {}
      end
    end,
  },
}
