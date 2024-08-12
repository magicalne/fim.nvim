# fim.nvim

Work in progress..

## Setup

```lua
local fim = require('fim.config')
fim:setup({
  max_lines = 100,
  provider = 'Ollama',
  provider_options = {
    model = 'starcoder2:3b',
    -- model = 'llama3.1',
  },
  notify = true,
  notify_callback = function(msg)
    vim.notify(msg)
  end,
  run_on_every_keystroke = false,
  ignored_file_types = {
    -- default is not to ignore
    -- uncomment to ignore in lua:
    -- lua = true
  },
})

```
