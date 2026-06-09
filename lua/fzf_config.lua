local fzf = require("fzf-lua")
fzf.setup({
  winopts = {
    height = 0.85,
    width = 0.80,
    preview = {
      layout = "vertical", -- vista previa vertical
    },
  },
})
vim.keymap.set("v", "g", fzf.buffers, { desc = "Buffers abiertos" })
vim.keymap.set("v", "k", fzf.oldfiles, { desc = "Archivos recientes" })
    
       
local original_buf = nil
local original_win = nil
local input_buf = nil
local input_win = nil

function _G.input_grep_live()
    original_buf = vim.api.nvim_get_current_buf()
    original_win = vim.api.nvim_get_current_win()

    input_buf = vim.api.nvim_create_buf(false, true)


    local width, height = 30, 1
    local row = vim.o.lines - height - 2  -- casi abajo del todo
    local col = 1                         -- parte izquierda
    
    input_win = vim.api.nvim_open_win(input_buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
    })
    vim.bo[input_buf].buftype = "prompt"
    vim.fn.prompt_setprompt(input_buf, "Buscar: ")
    -- Space → buscar y cerrar
    vim.keymap.set("i", "<Space>", function()
        _G.get_line()
    end, { buffer = input_buf })
    vim.cmd("startinsert")
end
           
local get_input = "manuel"  
function _G.get_line()
    local line = vim.api.nvim_get_current_line()
    local input = line:gsub("^Buscar:%s*", "")
    if input == "" then return end
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
    get_input = input 
    require("fzf-lua").live_grep({search = get_input,cwd = _G.master_dir})
end

vim.api.nvim_set_keymap("n", "l", ":lua _G.input_grep_live()<CR>" ,{ noremap = true, silent= true})
