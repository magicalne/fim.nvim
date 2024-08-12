local cmp = require('cmp')
local source = require('fim.source')
local M = {}


-- Setup function to initialize the plugin
M.setup = function()
  M.ai_source = source:new()
  cmp.register_source('fim', M.ai_source)
end

return M
