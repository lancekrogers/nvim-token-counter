-- nvim-token-counter plugin loader
if vim.g.loaded_nvim_token_counter then
  return
end
vim.g.loaded_nvim_token_counter = true

-- Create user commands
vim.api.nvim_create_user_command("TokenCounterRecount", function()
  require("nvim-token-counter").recount()
end, { desc = "Recount tokens for current buffer" })

vim.api.nvim_create_user_command("TokenCounterEnable", function()
  require("nvim-token-counter").enable()
end, { desc = "Enable token counter" })

vim.api.nvim_create_user_command("TokenCounterDisable", function()
  require("nvim-token-counter").disable()
end, { desc = "Disable token counter" })

vim.api.nvim_create_user_command("TokenCounterToggle", function()
  require("nvim-token-counter").toggle()
end, { desc = "Toggle token counter" })

vim.api.nvim_create_user_command("TokenCounterShow", function()
  local tc = require("nvim-token-counter")
  local count = tc.get_count()
  if count then
    vim.notify(
      string.format(
        "Tokens: %d | Characters: %d | Words: %d | Lines: %d",
        count.tokens,
        count.characters,
        count.words,
        count.lines
      ),
      vim.log.levels.INFO
    )
  else
    vim.notify("No token count available for this buffer", vim.log.levels.WARN)
  end
end, { desc = "Show token count details" })
