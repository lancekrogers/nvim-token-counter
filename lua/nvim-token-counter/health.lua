-- Health check module for nvim-token-counter
-- Run with :checkhealth nvim-token-counter
local M = {}

function M.check()
  vim.health.start("nvim-token-counter")

  -- Check Neovim version
  if vim.fn.has("nvim-0.9.0") == 1 then
    vim.health.ok("Neovim >= 0.9.0")
  else
    vim.health.error("Neovim < 0.9.0 required", {
      "Upgrade Neovim to 0.9.0 or higher",
    })
  end

  -- Check tcount binary
  local config = require("nvim-token-counter.config")
  local tcount_path = config.options.tcount_path
  if tcount_path == nil or tcount_path == "" then
    tcount_path = "tcount"
  end

  if vim.fn.executable(tcount_path) == 1 then
    vim.health.ok("tcount found: " .. tcount_path)

    -- Check tcount runs
    local output = vim.fn.system({ tcount_path, "--help" })
    if vim.v.shell_error == 0 then
      vim.health.ok("tcount executes successfully")
    else
      vim.health.warn("tcount found but failed to execute", {
        "Try running: " .. tcount_path .. " --help",
      })
    end
  else
    vim.health.error("tcount not found", {
      "Install via Homebrew: brew install lancekrogers/tap/tcount",
      "Install via Go: go install github.com/lancekrogers/go-token-counter/cmd/tcount@latest",
      "Or download from: https://github.com/lancekrogers/go-token-counter/releases",
    })
  end

  -- Check lualine
  local ok, _ = pcall(require, "lualine")
  if ok then
    vim.health.ok("lualine.nvim installed")
  else
    vim.health.warn("lualine.nvim not found", {
      "lualine is required for statusline display",
      "The plugin API still works without it",
    })
  end

  -- Show current config
  vim.health.info("Model: " .. (config.options.model or "not set"))
  vim.health.info("Enabled: " .. tostring(config.options.enabled))
end

return M
