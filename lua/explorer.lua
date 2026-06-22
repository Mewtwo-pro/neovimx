-- 0 oculta la cabecera, 1 la muestra
vim.g.netrw_banner = 0
-- Creamos un grupo pa los autocomandos de netrw
local netrw_group = vim.api.nvim_create_augroup("MiNetrwConfig", { clear = true })
--renombar 

local original_buf = nil
local original_win = nil
local input_buf = nil
local input_win = nil
local name_dired = "veneca"
local dired = nil
function _G.input_netrw_rename()
    
    local dir = vim.b.netrw_curdir
    if not dir then
        return
    end

    local old_name = vim.fn.expand("<cfile>")

    if old_name == "" then
        return
    end
    dired = dir
    name_dired = old_name  
    print(name_dired)
        
    original_buf = vim.api.nvim_get_current_buf()
    original_win = vim.api.nvim_get_current_win()

    input_buf = vim.api.nvim_create_buf(false, true)

    local width, height = 30, 1
    local row, col = 0, vim.o.columns - width

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
    vim.fn.prompt_setprompt(input_buf, "rename: ")
    -- Space → buscar y cerrar
    vim.keymap.set("i", "<Space>", function()
        _G.NetrwRename()
    end, { buffer = input_buf })
    vim.cmd("startinsert")
end
 
function _G.NetrwRename()
    
    local line = vim.api.nvim_get_current_line()
    local input = line:gsub("^rename:%s*", "")
    if input == "" then return end
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
       
    local new_name = input
    local old_name = name_dired 
    local dir = dired
           
    if not new_name or new_name == "" or new_name == old_name then
        return
    end

    local old_path = dir .. "/" .. old_name
    local new_path = dir .. "/" .. new_name 

    local ok = vim.fn.rename(old_path, new_path)

    if ok ~= 0 then
        vim.notify("Error al renombrar", vim.log.levels.ERROR)
        return
    end

    vim.cmd("edit " .. vim.fn.fnameescape(dir))
end

-- crear nueva file
function _G.input_netrw_new_file()
    original_buf = vim.api.nvim_get_current_buf()
    original_win = vim.api.nvim_get_current_win()

    input_buf = vim.api.nvim_create_buf(false, true)

    local width, height = 30, 1
    local row, col = 0, vim.o.columns - width

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
    vim.fn.prompt_setprompt(input_buf, "newFile: ")
    -- Space → buscar y cerrar
    vim.keymap.set("i", "<Space>", function()
        _G.NetrwCreateFile()
    end, { buffer = input_buf })
    vim.cmd("startinsert")
end
 
function _G.NetrwCreateFile()
    
    local line = vim.api.nvim_get_current_line()
    local input = line:gsub("^newFile:%s*", "")
    if input == "" then return end
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
       
    local dir = vim.b.netrw_curdir
    if not dir then
        return
    end
      
    local path = dir .. "/" .. input 
    if input:sub(-1) == "/" then
       path = path:sub(1, -2) 
       vim.fn.mkdir(path, "p")
    else
        local fd = io.open(path, "w")
        if fd then
            fd:close()
        end
    end

    vim.cmd("edit " .. vim.fn.fnameescape(dir))
end

        
local function abrir_netrw_en_ruta()
  -- 1. Obtenemos la ruta del buffer actual
  local ruta = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
  
  -- 2. Abrimos una nueva pestaña
  vim.cmd('tabnew')
  
  -- 3. Entramos a la carpeta usando el comando 'Explore' (que es el comando completo de :Ex)
  -- 'Explore' sí acepta la ruta como argumento
  vim.cmd('Explore ' .. ruta)
end

-- Mapeo
vim.keymap.set('v', 'x', abrir_netrw_en_ruta, { desc = "Abrir netrw en la carpeta del buffer actual en nueva tab" })
        

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  group = netrw_group,
  callback = function()
    -- nnoremap <buffer> ... en Lua:
    local opts = { buffer = true, noremap = true, silent = true }
    vim.keymap.set('n', 'q', ':q<CR>', opts)
    vim.keymap.set('n', 'o', '<Down>', opts)
    vim.keymap.set('n', 'p', 'k', opts)
    vim.keymap.set("n", "d", function()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes("D", true, false, true),
        "m",
        false
    )
end, opts)
    vim.keymap.set("n", "e", _G.input_netrw_new_file, { buffer = true })
    vim.keymap.set("n", "r", _G.input_netrw_rename, { buffer = true })
  end,
})
    
_G.master_dir = nil 
vim.api.nvim_create_autocmd("FileType", {
    pattern = "netrw",
    group = netrw_group,
    callback = function()

        local opts = {
            buffer = true,
            noremap = true,
            silent = true,
        }

        vim.keymap.set("n", "a", function()
            print(vim.b.netrw_curdir)
        end, opts)

        vim.keymap.set("n", "c", function()
            _G.path_filex =vim.b.netrw_curdir
            _G.input_git_net() 
        end, opts)

        vim.keymap.set("n", "u", function()
            local dir = vim.b.netrw_curdir

            if not dir then
                vim.notify("No estás en netrw")
                return
            end
            _G.master_dir = dir 
            print("grep path :" .. _G.master_dir)           
            vim.cmd('q')
        end, opts)
    end,
})
