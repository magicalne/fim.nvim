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

## Add source of cmp

```lua
  sources = cmp.config.sources({
    -- TODO: currently snippets from lsp end up getting prioritized -- stop that!
    { name = 'nvim_lsp' },
    { name = 'vsnip' },
    { name = 'fim'},
  }, {
    { name = 'path' },
  }),
```

## Reset mapping

```lua
      ['<C-x>'] = cmp.mapping(
          cmp.mapping.complete({
            config = {
              sources = cmp.config.sources({
                { name = 'fim' },
              }),
            },
          }),
          { 'i' }
    ),
```


## Problems:

- codegemma not working on ollama

