-- nvim-token-counter: Display token counts in lualine using fest count
-- Main entry point for the plugin

local M = {}

---@class TokenCounterConfig
---@field model string Model for tokenization (default: "claude-3")
---@field icon string Icon to display (default: "󰊄")
---@field fest_path string Path to fest binary (default: "fest")
---@field format string Display format (default: "%s %s")
---@field enabled boolean Enable/disable the plugin (default: true)
---@field filetypes_exclude string[] Filetypes to exclude from counting

---Setup the plugin
---@param opts TokenCounterConfig|nil
function M.setup(opts)
  local config = require("nvim-token-counter.config")
  config.setup(opts)

  -- Verify fest is available
  if vim.fn.executable(config.options.fest_path) ~= 1 then
    vim.notify(
      "[nvim-token-counter] fest not found at: " .. config.options.fest_path,
      vim.log.levels.WARN
    )
    return
  end

  -- Set up autocommands
  local augroup = vim.api.nvim_create_augroup("nvim-token-counter", { clear = true })

  -- Count tokens on save (invalidate cache first)
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = augroup,
    callback = function(args)
      local cache = require("nvim-token-counter.cache")
      cache.invalidate(args.buf)
      require("nvim-token-counter.counter").trigger_count(args.buf)
    end,
    desc = "Count tokens on file save",
  })

  -- Initial count for buffer on enter (if not cached)
  vim.api.nvim_create_autocmd("BufEnter", {
    group = augroup,
    callback = function(args)
      local cache = require("nvim-token-counter.cache")
      -- Only count if not already cached
      if not cache.get(args.buf) then
        -- Defer to avoid blocking
        vim.defer_fn(function()
          require("nvim-token-counter.counter").trigger_count(args.buf)
        end, 100)
      end
    end,
    desc = "Count tokens on buffer enter (if not cached)",
  })

  -- Clean up cache when buffer is deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    callback = function(args)
      require("nvim-token-counter.cache").invalidate(args.buf)
    end,
    desc = "Clean up token cache on buffer delete",
  })

  -- Count for currently open buffer on setup
  vim.defer_fn(function()
    require("nvim-token-counter.counter").trigger_count()
  end, 200)
end

---Get the lualine component function
---@return function
function M.lualine_component()
  return require("nvim-token-counter.lualine").component
end

---Get the lualine condition function
---@return boolean
function M.lualine_cond()
  return require("nvim-token-counter.lualine").cond
end

---Manually trigger a recount for current buffer
function M.recount()
  local cache = require("nvim-token-counter.cache")
  local bufnr = vim.api.nvim_get_current_buf()
  cache.invalidate(bufnr)
  require("nvim-token-counter.counter").trigger_count(bufnr)
end

---Enable the plugin
function M.enable()
  require("nvim-token-counter.config").options.enabled = true
  -- Trigger lualine refresh
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.refresh()
  end
end

---Disable the plugin
function M.disable()
  require("nvim-token-counter.config").options.enabled = false
  -- Trigger lualine refresh
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.refresh()
  end
end

---Toggle the plugin
function M.toggle()
  local config = require("nvim-token-counter.config")
  config.options.enabled = not config.options.enabled
  -- Trigger lualine refresh
  local ok, lualine = pcall(require, "lualine")
  if ok then
    lualine.refresh()
  end
end

---Get current token count for buffer
---@param bufnr number|nil
---@return table|nil
function M.get_count(bufnr)
  return require("nvim-token-counter.cache").get(bufnr or vim.api.nvim_get_current_buf())
end

return M
