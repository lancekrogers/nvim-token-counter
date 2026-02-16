-- Configuration module for nvim-token-counter
local M = {}

---@class TokenCounterConfig
---@field model string Model for tokenization (default: "claude-4.5-sonnet")
---@field icon string Icon to display (default: "󰊄")
---@field tcount_path string Path to tcount binary (default: "tcount")
---@field format string Display format (default: "%s %s")
---@field enabled boolean Enable/disable the plugin (default: true)
---@field filetypes_exclude string[] Filetypes to exclude from counting

M.defaults = {
  model = "claude-4.5-sonnet",
  icon = "󰊄",
  tcount_path = "tcount",
  format = "%s %s", -- icon, formatted_count
  enabled = true,
  filetypes_exclude = {
    "neo-tree",
    "dashboard",
    "lazy",
    "mason",
    "help",
    "qf",
    "alpha",
    "toggleterm",
    "TelescopePrompt",
    "NvimTree",
    "Trouble",
  },
}

---@type TokenCounterConfig
M.options = {}

---Setup configuration with user options
---@param opts TokenCounterConfig|nil
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})

  -- Auto-detect tcount path if not explicitly set and not in PATH
  if M.options.tcount_path == "tcount" then
    local tcount_in_path = vim.fn.executable("tcount") == 1
    if not tcount_in_path then
      local possible_paths = {
        "/opt/homebrew/bin/tcount",
        "/usr/local/bin/tcount",
        vim.fn.expand("~/go/bin/tcount"),
        vim.fn.expand("~/.local/bin/tcount"),
      }
      for _, path in ipairs(possible_paths) do
        if vim.fn.executable(path) == 1 then
          M.options.tcount_path = path
          break
        end
      end
    end
  end
end

return M
