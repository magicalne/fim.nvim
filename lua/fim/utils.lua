local M = {}

function M.indentAlignment(response)
    local indent = vim.fn.indent(vim.fn.line('.'))
    -- Split the completion code into lines
    local lines = vim.split(extracted_code, "\n")
    -- add indent for each line
    local indented_lines = {}
    for _, line in ipairs(lines) do
      table.insert(indented_lines, string.rep(' ', indent) .. line)
    end
    -- concat indented_lines to string
    return table.concat(indented_lines, "\n") .. "\n"
end
   
return M
