-- Per-buffer caching module for nvim-token-counter
local M = {}

---@class CacheEntry
---@field tokens number Token count
---@field characters number Character count
---@field words number Word count
---@field lines number Line count
---@field timestamp number When the cache was created

---@type table<number, CacheEntry>
M.buffer_cache = {}

---Store data in cache for a buffer
---@param bufnr number Buffer number
---@param data CacheEntry
function M.set(bufnr, data)
  data.timestamp = vim.loop.now()
  M.buffer_cache[bufnr] = data
end

---Get cached data for a buffer
---@param bufnr number Buffer number
---@return CacheEntry|nil
function M.get(bufnr)
  return M.buffer_cache[bufnr]
end

---Invalidate cache for a buffer
---@param bufnr number Buffer number
function M.invalidate(bufnr)
  M.buffer_cache[bufnr] = nil
end

---Clear all cache entries
function M.clear()
  M.buffer_cache = {}
end

---Clean up cache for deleted buffers
function M.cleanup()
  local valid_buffers = {}
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    valid_buffers[bufnr] = true
  end

  for bufnr in pairs(M.buffer_cache) do
    if not valid_buffers[bufnr] then
      M.buffer_cache[bufnr] = nil
    end
  end
end

return M
