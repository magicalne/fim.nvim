local M = {}
local ts_utils = require('nvim-treesitter.ts_utils')
local curl = require("plenary.curl")

local config = {}

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
    local prompt = string.format(config.template, prefix, suffix)

    print(prompt)
    
    local response = curl.post(config.api_url, {
        body = vim.fn.json_encode({
            model = config.model,
            prompt = prompt,
            stream = false,
            options = {
                temperature = config.temperature,
                num_predict = config.num_predict 
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
        if completed_code then
            -- Insert the completed code
            local bufnr = vim.api.nvim_get_current_buf()
            local cursor = vim.api.nvim_win_get_cursor(0)
            vim.api.nvim_buf_set_lines(bufnr, cursor[1], cursor[1], false, vim.split(completed_code, "\n"))
        end
    else
        print("Unable to extract function parts")
    end
end

return M

