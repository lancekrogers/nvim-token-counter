-- Configuration module for nvim-token-counter
local M = {}

---@class TokenCounterConfig
---@field model string Model for tokenization (default: "claude-3")
---@field icon string Icon to display (default: "󰊄")
---@field fest_path string Path to fest binary (default: "fest")
---@field format string Display format (default: "%s %s")
---@field enabled boolean Enable/disable the plugin (default: true)
---@field filetypes_exclude string[] Filetypes to exclude from counting

M.defaults = {
  model = "claude-3",
  icon = "󰊄",
  fest_path = "fest",
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

  -- Auto-detect fest path if not explicitly set and not in PATH
  if M.options.fest_path == "fest" then
    local fest_in_path = vim.fn.executable("fest") == 1
    if not fest_in_path then
      local possible_paths = {
        vim.fn.expand("~/go/bin/fest"),
        "/usr/local/bin/fest",
        vim.fn.expand("~/.local/bin/fest"),
      }
      for _, path in ipairs(possible_paths) do
        if vim.fn.executable(path) == 1 then
          M.options.fest_path = path
          break
        end
      end
    end
  end
end

return M
