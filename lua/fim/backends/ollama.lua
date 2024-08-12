local requests = require('fim.requests')
local templates = require('fim.templates')

Ollama = requests:new(nil)

function Ollama:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  local template = templates.getTemplate(o.model)
  
  local prompt = template.prompt
  local stop = template.stop
  self.params = vim.tbl_deep_extend('keep', o or {}, {
    base_url = 'http://127.0.0.1:11434/api/generate',
    model = o.model,
    prompt = prompt,
    options = {
      num_predict = 128,
      temperature = 0.2,
      stop = stop,
    },
  })

  return o
end

function Ollama:complete(lines_before, lines_after, cb)
  -- format prompt
  local prompt = string.format(self.params.prompt, lines_before, lines_after)
  local data = {
    model = self.params.model,
    prompt = prompt,
    keep_alive = self.params.keep_alive,
    -- template = self.params.template,
    -- system = self.params.system,
    stream = false,
    --suffix = self.params.suffix and self.params.suffix(lines_after),
    options = self.params.options,
    raw = false,
  }

  self:Get(self.params.base_url, {}, data, function(answer)
    local new_data = {}
    if answer.error ~= nil then
      vim.notify('Ollama error: ' .. answer.error)
      return
    end
    if answer.done then
      local result = answer.response:gsub('\\n', '\n')
      table.insert(new_data, result)
    end
    cb(new_data)
  end)
end

function Ollama:test()
  self:complete('def factorial(n)\n    if', '    return ans\n', function(data)
    dump(data)
  end)
end

return Ollama

