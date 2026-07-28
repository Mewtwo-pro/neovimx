_G.pal_remplazar = "def" 
_G.pal_buscar = "def" 
local input_var1
local input_win_id

local original_buf = nil
local original_win = nil
local input_buf = nil
local input_win = nil

function _G.input_buscador()
    original_buf = vim.api.nvim_get_current_buf()
    original_win = vim.api.nvim_get_current_win()
    input_buf = vim.api.nvim_create_buf(false, true)

    local width, height = 30, 1
    
    local row = vim.o.lines - height - 3
    local col = vim.o.columns - width - 2
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
        _G.get_search_line()
    end, { buffer = input_buf })
    vim.cmd("startinsert")
end
 
function _G.get_search_next()
vim.fn.feedkeys("/\\c" .. vim.fn.escape(pal_buscar, "/\\") .. "\n", "n")
end

function _G.get_search_line()
    vim.api.nvim_set_keymap("n", "<BS>", ":lua _G.get_search_next()<CR>", { noremap = true, silent = true }) vim.api.nvim_set_keymap("n", "<Space>", ":lua _G.get_search_prev()<CR>", { noremap = true, silent = true })
    local line = vim.api.nvim_get_current_line()
    local input = line:gsub("^Buscar:%s*", "")
    if input == "" then return end
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
    pal_buscar = input 
    get_search_prev()
   
end
    
vim.api.nvim_set_keymap("n", "j", "ma:lua _G.input_buscador()<CR>" ,{ noremap = true, silent= true})
vim.api.nvim_set_keymap("v", "j", "<Esc>ma:lua _G.input_buscador()<CR>" ,{ noremap = true, silent= true})

function _G.search_current()
    vim.api.nvim_set_keymap("n", "<BS>", ":lua _G.get_search_next()<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", "<Space>", ":lua _G.get_search_prev()<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", "-", ":lua replaze_palabra()<CR>", { noremap = true, silent = true })
    print("buscando : " .. pal_buscar)
end   
vim.api.nvim_set_keymap("v", "w", "<Esc>ma:lua _G.search_current()<CR>", { noremap = true, silent = true })
function _G.get_search_prev()
    vim.fn.feedkeys("?\\c" .. vim.fn.escape(pal_buscar, "/\\") .. "\n", "n")
end
 

 
function _G.off_light()
    vim.api.nvim_win_close(input_win_id, true)
    vim.fn.feedkeys(":noh\n","n")
end


  
function _G.auto_search_line()
    vim.api.nvim_set_keymap("n", "<BS>", ":lua _G.get_search_next()<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("n", "<Space>", ":lua _G.get_search_prev()<CR>", { noremap = true, silent = true })
    local palabra = vim.fn.expand("<cword>")  -- obtiene la palabra bajo el cursor
    pal_buscar = palabra
    vim.fn.feedkeys("/" .. palabra .. "\n", "n")
end

-- Definir la función en Lua
function PrintVisualSelection()
  -- Obtener la posición inicial y final de la selección visual
  local start_pos = vim.fn.getpos("'<")
  local end_pos   = vim.fn.getpos("'>")

  -- Extraer las líneas seleccionadas
  local lines = vim.fn.getline(start_pos[2], end_pos[2])

  -- Recortar según columnas
  lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  lines[1]      = string.sub(lines[1], start_pos[3])

  -- Unir y mostrar
  local selection = table.concat(lines, "\n")
  pal_buscar = selection
  vim.fn.feedkeys("/" .. pal_buscar .. "\n", "n")
  _G.search_current() 
end

vim.api.nvim_set_keymap("v", "v", "<Esc>ma:lua PrintVisualSelection()<CR>", { noremap = true })
--vim.api.nvim_set_keymap("v", "m", "<Esc>:lua _G.auto_search_line()<CR>", { noremap = true, silent = true })
--vim.api.nvim_set_keymap("v", "o", "<Esc>ggVG", { noremap = true, silent = true })
    
           
local search_buf, search_win
local replace_buf, replace_win
local replace_text = ""

-- ---------- INPUT BUSCAR ----------
function _G.open_replace_input()
    replace_buf = vim.api.nvim_create_buf(false, true)

    replace_win = vim.api.nvim_open_win(replace_buf, true, {
        relative = "editor",
        width = 30,
        height = 1,
        row = 4,
        col = vim.o.columns - 32,
        style = "minimal",
        border = "rounded",
    })

    vim.bo[replace_buf].buftype = "prompt"
    vim.fn.prompt_setprompt(replace_buf, "Reemplazar: ")

    -- Space → cerrar todo
    vim.keymap.set("i", "<Space>", function()
        local line = vim.api.nvim_get_current_line()
        replace_text = line:gsub("^Reemplazar:%s*", "")

        vim.api.nvim_win_close(replace_win, true)
        vim.api.nvim_buf_delete(replace_buf, { force = true })
        pal_remplazar = replace_text
        _G.get_search_next()
-- Asignar a ';' para ejecutar la función
        vim.api.nvim_set_keymap("n", "<BS>", ":lua _G.get_search_next()<CR>", { noremap = true, silent = true }) vim.api.nvim_set_keymap("n", "<Space>", ":lua _G.get_search_prev()<CR>", { noremap = true, silent = true })
        vim.api.nvim_set_keymap("n", "-", ":lua replaze_palabra()<CR>", { noremap = true, silent = true })
           
        print("Reemplazar: " .. pal_remplazar)
    end, { buffer = replace_buf })

    vim.cmd("startinsert")
end

-- ---------- MAPA EN NORMAL ----------
vim.keymap.set("v", "h", function()
    replace_text = ""
    _G.open_replace_input()
end, { noremap = true, silent = true })

function replaze_palabra()
    vim.cmd("s//" .. vim.fn.escape(pal_remplazar, "/") .. "/")
    _G.get_search_next()
    --vim.fn.feedkeys(":%s//" .. pal_remplazar .. "\n", "n")
    --vim.fn.feedkeys(":%s//manuel/g\n", "n")
end
function full_replase_palabra()
    vim.fn.feedkeys(":%s//" .. pal_remplazar .. "\n", "n")
end

--vim.api.nvim_set_keymap("v", "2", ":lua full_replase_palabra()<CR>", { noremap = true, silent = true })
