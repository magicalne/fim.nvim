local M = {}

-- Default configuration
local default_config = {
    model = "stable-code:3b-code",
    api_url = "http://localhost:11434/api/generate",
    temperature = 0.2,
    template = "<fim_prefix>%s<fim_suffix>%s<fim_middle>",
    num_predict = 48,
    context_lines = 5,  -- Number of lines to extract above/below cursor when not in a function
}

-- Ensure required dependencies are available
local function check_dependencies()
    local required = {
        "nvim-treesitter",
        "plenary"
    }

    for _, plugin in ipairs(required) do
        local ok, _ = pcall(require, plugin)
        if not ok then
            error(string.format("This plugin requires %s. Please install it and try again.", plugin))
        end
    end
end

-- Setup function to initialize the plugin
function M.setup(opts)
    opts = opts or {}
    
    check_dependencies()
    -- Merge user options with defaults
    M.config = vim.tbl_deep_extend("force", default_config, opts)
    -- Load the ollama module
    local fim= require("fim.fim")
    fim.set_config(M.config)  -- Pass the config to ollama module
    -- Create user command
    vim.api.nvim_create_user_command("FIM", function()
        fim.fill_in_middle(config)
    end, {})

    -- Optional: Set up key mappings
    if opts.mappings ~= false then
        vim.keymap.set('n', '<leader>fm', ':FIM<CR>', { noremap = true, silent = true, desc = "Fill In Middle" })
    end
end

return M
