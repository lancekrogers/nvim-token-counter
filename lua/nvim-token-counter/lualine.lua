-- Lualine component integration for nvim-token-counter
local config = require("nvim-token-counter.config")
local counter = require("nvim-token-counter.counter")
local cache = require("nvim-token-counter.cache")

local M = {}

---Lualine component function
---@return string|nil
function M.component()
  if not config.options.enabled then
    return nil
  end

  local bufnr = vim.api.nvim_get_current_buf()

  -- Check filetype exclusions
  local filetype = vim.bo[bufnr].filetype
  if vim.tbl_contains(config.options.filetypes_exclude, filetype) then
    return nil
  end

  -- Return cached display string
  return counter.get_display_string(bufnr)
end

---Condition function for lualine (show component only when data available)
---@return boolean
function M.cond()
  if not config.options.enabled then
    return false
  end

  local bufnr = vim.api.nvim_get_current_buf()

  -- Check filetype exclusions
  local filetype = vim.bo[bufnr].filetype
  if vim.tbl_contains(config.options.filetypes_exclude, filetype) then
    return false
  end

  return cache.get(bufnr) ~= nil
end

return M
