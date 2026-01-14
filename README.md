# nvim-token-counter

A Neovim plugin that displays token counts in your status line using the `fest count` command from the [Festival Methodology](https://github.com/obediencecorp/festival-methodology) CLI.

## Features

- Displays token count in lualine status line
- Async execution (non-blocking, ~73ms per file)
- Per-buffer caching (no redundant calls)
- Updates on save (BufWritePost)
- Supports multiple tokenizer models (Claude, GPT-4, GPT-3.5)
- Formatted numbers with commas (1,234)

## Requirements

- Neovim >= 0.9.0
- [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)
- [fest CLI](https://github.com/obediencecorp/festival-methodology) installed and in PATH

## Installation

### lazy.nvim

```lua
return {
  "lancekrogers/nvim-token-counter",
  -- Or for local development:
  -- dir = "~/path/to/nvim-token-counter",

  dependencies = { "nvim-lualine/lualine.nvim" },
  event = "BufReadPost",

  opts = {
    model = "claude-3",     -- Tokenizer model
    icon = "󰊄",            -- Display icon (nerd font)
    fest_path = "fest",     -- Path to fest binary (auto-detected)
  },

  config = function(_, opts)
    require("nvim-token-counter").setup(opts)

    -- Add to lualine
    local lualine = require("lualine")
    local tc = require("nvim-token-counter")
    local config = lualine.get_config()

    table.insert(config.sections.lualine_x, 1, {
      tc.lualine_component(),
      cond = tc.lualine_cond(),
    })

    lualine.setup(config)
  end,
}
```

### LazyVim (lualine override method)

If you prefer to keep the lualine configuration separate:

```lua
-- lua/plugins/token-counter.lua
return {
  {
    "lancekrogers/nvim-token-counter",
    dependencies = { "nvim-lualine/lualine.nvim" },
    event = "BufReadPost",
    opts = {
      model = "claude-3",
      icon = "󰊄",
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local tc = require("nvim-token-counter")
      table.insert(opts.sections.lualine_x, 1, {
        tc.lualine_component(),
        cond = tc.lualine_cond(),
      })
      return opts
    end,
  },
}
```

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `model` | string | `"claude-3"` | Tokenizer model (`claude-3`, `gpt-4`, `gpt-3.5-turbo`) |
| `icon` | string | `"󰊄"` | Icon displayed before token count |
| `fest_path` | string | `"fest"` | Path to fest binary (auto-detected if in PATH) |
| `format` | string | `"%s %s"` | Display format (icon, count) |
| `enabled` | boolean | `true` | Enable/disable the plugin |
| `filetypes_exclude` | table | `{...}` | Filetypes to skip (neo-tree, help, etc.) |

## Commands

| Command | Description |
|---------|-------------|
| `:TokenCounterRecount` | Force recount for current buffer |
| `:TokenCounterEnable` | Enable the plugin |
| `:TokenCounterDisable` | Disable the plugin |
| `:TokenCounterToggle` | Toggle enable/disable |
| `:TokenCounterShow` | Show detailed count (tokens, chars, words, lines) |

## API

```lua
local tc = require("nvim-token-counter")

-- Setup with options
tc.setup({ model = "claude-3", icon = "󰊄" })

-- Get lualine component and condition functions
tc.lualine_component()  -- Returns the component function
tc.lualine_cond()       -- Returns the condition function

-- Manual control
tc.recount()            -- Force recount current buffer
tc.enable()             -- Enable plugin
tc.disable()            -- Disable plugin
tc.toggle()             -- Toggle enabled state

-- Get raw count data
local count = tc.get_count()
if count then
  print(count.tokens)      -- Token count
  print(count.characters)  -- Character count
  print(count.words)       -- Word count
  print(count.lines)       -- Line count
end
```

## How It Works

1. On buffer enter (first time) or save, the plugin runs `fest count --json --model <model> <filepath>`
2. The command executes asynchronously using `vim.fn.jobstart()` (~73ms)
3. Results are cached per-buffer until the next save
4. The lualine component reads from cache and displays formatted count
5. Cache is cleaned up when buffers are deleted

## License

MIT
