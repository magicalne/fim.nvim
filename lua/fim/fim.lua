local M = {}
local ts_utils = require('nvim-treesitter.ts_utils')
local curl = require("plenary.curl")

local config = {}

local function extract_completion_code(response)
  -- Extract the content between <COMPLETION> tags
  local code = response:match("<COMPLETION>(.-)</COMPLETION>")
  
  if code then
    -- Trim leading and trailing whitespace
    code = code:match("^%s*(.-)%s*$")
    
    -- Remove any common indentation
    local indent = code:match("^%s+")
    if indent then
      local pattern = "^" .. indent
      code = code:gsub(pattern, "", 1)  -- Remove from first line
      code = code:gsub("\n" .. pattern, "\n")  -- Remove from other lines
    end
  end
  
  return code
end

function M.set_config(new_config)
    config = new_config
end

-- Function to extract function signature using Tree-sitter and split into prefix and suffix
function M.extract_function_parts()
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor_node = ts_utils.get_node_at_cursor()
    
    if not cursor_node then return nil end

    -- Function to find the function node
    local function find_function_node(node)
        while node do
            if node:type() == "function_definition" or 
               node:type() == "function_declaration" or
               node:type() == "method_definition" then
                return node
            end
            node = node:parent()
        end
        return nil
    end

    local function_node = find_function_node(cursor_node)

    if function_node then
        -- If we're in a function, use the existing logic
        local start_row, start_col, end_row, end_col = function_node:range()
        local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
        local full_function = table.concat(lines, "\n")

        local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
        local cursor_pos = cursor_row - start_row - 1  -- Adjust for 0-based index

        local prefix = table.concat(vim.list_slice(lines, 1, cursor_pos + 1), "\n")
        local suffix = table.concat(vim.list_slice(lines, cursor_pos + 1), "\n")

        return prefix, suffix
    else
        -- If we're not in a function, take `` lines above and below
        local cursor_row, _ = unpack(vim.api.nvim_win_get_cursor(0))
        local start_row = math.max(0, cursor_row - config.context_lines - 1)  -- -6 because cursor_row is 1-indexed
        local end_row = cursor_row + config.context_lines
        local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
        
        local prefix_lines = vim.list_slice(lines, 1, cursor_row - start_row)
        local suffix_lines = vim.list_slice(lines, cursor_row - start_row + 1)

        local prefix = table.concat(prefix_lines, "\n")
        local suffix = table.concat(suffix_lines, "\n")

        return prefix, suffix
    end
end

-- Function to send request to Ollama API with FIM format
function M.send_to_ollama(prefix, suffix)

    local template = require('fim.templates')
    local general_template = template.getTemplate("general")
    local prompt = string.format(general_template, prefix, suffix)

    -- print(prompt)
    
    local response = curl.post(config.api_url, {
        body = vim.fn.json_encode({
            model = config.model,
            prompt = prompt,
            stream = false,
            options = {
                temperature = config.temperature,
                num_predict = config.num_predict,
            }
        }),
        headers = {
            content_type = "application/json"
        }
    })

    if response.status == 200 then
        local result = vim.fn.json_decode(response.body)
        print("response: ", result.response)
        local response = result.response
        response = response:gsub("\n+", "\n")
        return response
 

    else
        print("Error calling Ollama API:", response.status)
        return nil
    end
end

-- Main function to fill in the middle
function M.fill_in_middle()
    local prefix, suffix = M.extract_function_parts()
    if prefix and suffix then
        local completed_code = M.send_to_ollama(prefix, suffix)
        local extracted_code = extract_completion_code(completed_code)
        if extracted_code then
          print(extracted_code)
        else
          print("No completion found in the response")
        end
        if extracted_code then
            -- 
            local buf = vim.api.nvim_get_current_buf()
            -- Get the cursor position
            local row, col = unpack(vim.api.nvim_win_get_cursor(0))
            
            local indent = vim.fn.indent(vim.fn.line('.'))
            -- Split the completion code into lines
            local lines = vim.split(extracted_code, "\n")
            -- add indent for each line
            local indented_lines = {}
            for _, line in ipairs(lines) do
              table.insert(indented_lines, string.rep(' ', indent) .. line)
            end
            
            -- Insert the completion code
            vim.api.nvim_buf_set_lines(buf, row - 1, row - 1, false, indented_lines)
            
            -- Move the cursor to the end of the inserted text
            local new_row = row + #indented_lines - 1
            local new_col = #indented_lines[#indented_lines]
            vim.api.nvim_win_set_cursor(0, {new_row, new_col})
        end
    else
        print("Unable to extract function parts")
    end
end

return M

