-- Per-repo run presets for <leader>rp. Each project matches on its repo root and
-- returns presets; `run` lists consoles (see config/runner.lua) started together.
return {
  {
    -- swisscom-login-idm monorepo (~/dev/idm)
    match = function(root)
      return vim.uv.fs_stat(root .. "/idm-lar/idm-lar-mocks") ~= nil
    end,
    presets = function(root, r)
      local lar_fe, reg_fe = root .. "/idm-lar/idm-lar-frontend", root .. "/idm-reg/idm-reg-frontend"
      local c = {
        lar_mocks = r.spring_boot(root, "idm-lar/idm-lar-mocks"),
        lar_backend = r.spring_boot(root, "idm-lar/idm-lar-backend"),
        lar_frontend = r.npm_script(lar_fe, "start:open"),
        lar_cypress = r.npm_script(lar_fe, "cy:open"),
        las = r.spring_boot(root, "idm-las"),
        reg_backend = r.spring_boot(root, "idm-reg/idm-reg-backend", {
          -- outbound calls through the local proxy (alpaca on :3128)
          jvm_args = {
            "-Dhttps.proxyHost=127.0.0.1",
            "-Dhttps.proxyPort=3128",
            "-Dhttp.proxyHost=127.0.0.1",
            "-Dhttp.proxyPort=3128",
            "-Dhttp.nonProxyHosts=localhost|127.*|[::1]",
          },
        }),
        reg_frontend = r.npm_script(reg_fe, "start:open"),
        reg_cypress = r.npm_script(reg_fe, "cy:open"),
      }
      return {
        { name = "LAR e2e: mocks + backend + frontend + Cypress", run = { c.lar_mocks, c.lar_backend, c.lar_frontend, c.lar_cypress } },
        { name = "LAR dev: mocks + backend + frontend", run = { c.lar_mocks, c.lar_backend, c.lar_frontend } },
        { name = "LAR mock server", run = { c.lar_mocks } },
        { name = "LAR backend", run = { c.lar_backend } },
        { name = "LAR frontend (open port)", run = { c.lar_frontend } },
        { name = "LAR Cypress open", run = { c.lar_cypress } },
        { name = "REG backend", run = { c.reg_backend } },
        { name = "REG frontend (open port)", run = { c.reg_frontend } },
        { name = "REG Cypress open", run = { c.reg_cypress } },
        { name = "LAS backend", run = { c.las } },
      }
    end,
  },
}
