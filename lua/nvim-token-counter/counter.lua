-- Core async token counting module for nvim-token-counter
local config = require("nvim-token-counter.config")
local cache = require("nvim-token-counter.cache")

local M = {}

---@type table<number, boolean>
M.pending_jobs = {}

---Format number with commas (1234 -> 1,234)
---@param n number
---@return string
function M.format_number(n)
  local formatted = tostring(n)
  local k
  while true do
    formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    if k == 0 then
      break
    end
  end
  return formatted
end

---Run tcount asynchronously for a buffer
---@param bufnr number Buffer number
---@param filepath string File path to count
---@param callback fun(result: CacheEntry|nil)
function M.count_async(bufnr, filepath, callback)
  -- Skip if already pending
  if M.pending_jobs[bufnr] then
    return
  end

  local opts = config.options
  local cmd = {
    opts.tcount_path,
    "--json",
    "--model",
    opts.model,
    filepath,
  }

  M.pending_jobs[bufnr] = true

  local stdout_data = {}

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.list_extend(stdout_data, data)
      end
    end,
    on_exit = function(_, exit_code)
      M.pending_jobs[bufnr] = nil

      -- Buffer may have been deleted while tcount was running
      if not vim.api.nvim_buf_is_valid(bufnr) then
        return
      end

      if exit_code ~= 0 then
        vim.schedule(function()
          vim.notify(
            "[nvim-token-counter] tcount failed (exit " .. exit_code .. "). Run :checkhealth nvim-token-counter",
            vim.log.levels.WARN,
            { once = true }
          )
        end)
        callback(nil)
        return
      end

      -- Parse JSON output
      local json_str = table.concat(stdout_data, "")
      local ok, result = pcall(vim.json.decode, json_str)

      if not ok or not result then
        vim.schedule(function()
          vim.notify(
            "[nvim-token-counter] Failed to parse tcount output",
            vim.log.levels.WARN,
            { once = true }
          )
        end)
        callback(nil)
        return
      end

      -- Extract token count from methods array
      local tokens = 0
      if result.methods and type(result.methods) == "table" and #result.methods > 0 then
        tokens = result.methods[1].tokens or 0
      end

      local cache_entry = {
        tokens = tokens,
        characters = result.characters or 0,
        words = result.words or 0,
        lines = result.lines or 0,
      }

      -- Store in cache
      cache.set(bufnr, cache_entry)

      callback(cache_entry)
    end,
  })
end

---Get formatted token string for display
---@param bufnr number|nil Buffer number (nil for current)
---@return string|nil
function M.get_display_string(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local opts = config.options

  local cached = cache.get(bufnr)
  if not cached then
    return nil
  end

  local formatted_count = M.format_number(cached.tokens)
  return string.format(opts.format, opts.icon, formatted_count)
end

---Trigger count for current buffer
---@param bufnr number|nil
function M.trigger_count(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Check if buffer is valid and has a file
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    return
  end

  -- Check filetype exclusions
  local filetype = vim.bo[bufnr].filetype
  if vim.tbl_contains(config.options.filetypes_exclude, filetype) then
    return
  end

  -- Check if it's a real file (not special buffer)
  local buftype = vim.bo[bufnr].buftype
  if buftype ~= "" then
    return
  end

  M.count_async(bufnr, filepath, function(result)
    if result then
      -- Trigger lualine refresh if available
      vim.schedule(function()
        local ok, lualine = pcall(require, "lualine")
        if ok then
          lualine.refresh()
        end
      end)
    end
  end)
end

return M
