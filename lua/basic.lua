vim.opt.foldmethod = 'indent'
vim.cmd("colorscheme catppuccin")
vim.opt.fillchars = "fold: "
vim.opt.foldtext = "getline(v:foldstart)"
vim.opt.wrap = false
local indent_cache = ""
function CaptureIndent()
          local line = vim.api.nvim_get_current_line()
          indent_cache = line:match("^%s*") or ""
  print("Indentation captured")
end
-- Configuración de indentación: tabs de 4 espacios
vim.opt.tabstop = 4      -- número de espacios que representa un tab
vim.opt.shiftwidth = 4   -- número de espacios para cada nivel de indentación
vim.opt.expandtab = true -- convierte tabs en espacios
vim.opt.softtabstop = 4  -- número de espacios al presionar <Tab>
vim.opt.hlsearch = true 
-- Aplica la indentación capturada a la línea actual
function ApplyIndent()
    local line = vim.api.nvim_get_current_line()
    local new_line = indent_cache .. line:gsub("^%s*", "")
    vim.api.nvim_set_current_line(new_line)
end 
vim.keymap.set('t', ';', [[<C-\><C-n>]], {noremap = true})
vim.keymap.set('n', 'l', function()
    local col = vim.fn.virtcol('.')
    local ancho = vim.api.nvim_win_get_width(0)

    vim.fn.winrestview({
        leftcol = math.max(0, col - math.floor(ancho / 2))
    })
end, { desc = "Centrar cursor horizontalmente" })
vim.api.nvim_set_keymap('n','gd', 'D', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','gs', 'd^', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','y', 'b', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','a', 'i', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','gh', 'G0', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','i', 'v', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i',';', '<Esc>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'g<Space>', ':', { noremap = true})
vim.api.nvim_set_keymap('n','q', 'zo', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','n', 'viw', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v','q', '<Esc>zR', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','z', 'zc', {noremap = true, silent = true })
vim.api.nvim_set_keymap('v','z', '<Esc>zM', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v','n', '<Esc>:q!<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'm', '<C-w>w', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'm', '<DEL>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v','b', '<Esc>:tabnew<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','b', ':tabNext<CR>', { noremap = true, silent = true })
--vim.api.nvim_set_keymap('n','n', ':tabnext<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v','o', '<Esc><C-w>s', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'u', '"+yy', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'w', '"+p', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'x', 'dd', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'r', '"+dd', { noremap = true, silent = true })
  
vim.api.nvim_set_keymap('v', 'u', '"+yy<Esc>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'r', '"+dd<Esc>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<BackSpace>', '<Del>', { noremap = true, silent = true })
 
vim.api.nvim_set_keymap('n', 'p', '<Up>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'o', '<Down>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('n', 'e', '<Right>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'k', '<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 's', '<Esc>^', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'd', '<Esc>$', { noremap = true, silent = true })
vim.keymap.set("n", "<BackSpace>", "v", { noremap = true, silent = true })
vim.keymap.set("i", "<Tab><Space>", "<Esc>^:call append(line('.'), repeat(' ', indent('.')))<CR>ja<Tab>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 's', ':w!<CR>', { noremap = true, silent = true })
vim.keymap.set("v", "p", ">gv", { noremap = true, silent = true })
vim.keymap.set("v","l", "<gv", { noremap = true, silent = true })
 
  
vim.api.nvim_set_keymap('i',"<Tab><CR>", '<Right><Esc>:lua CaptureIndent()<CR>i<CR><Esc>:lua ApplyIndent()<CR><Up>o', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>i', '+', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab><Tab>', '<Right>', { noremap = true, silent = true })

vim.api.nvim_set_keymap('i','<Tab>;', '<Right>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>t', '*', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>v', '-', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>w', ',', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>e', '$', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>r', '()<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>a', ':', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>s', '.', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>d', '=', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>f', '/', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>z', '<><Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>x', '&', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>c', '""<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>n', '\\', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>m', '|', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>b', '!', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>p', '[]<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>oa', '@', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>om','#', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>u', ';', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>l', "''<Left>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>q', '{}<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>j', '``<Left>', { noremap = true, silent = true })
--vim.api.nvim_set_keymap('i','<Tab>g', '<Esc>vUa', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>y', '%', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>h', '?', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>k', '_', { noremap = true, silent = true })

vim.api.nvim_set_keymap('i','-', '<Esc>vUa', { noremap = true, silent = true })
    
vim.keymap.set('n', '<BS>', 'u', { noremap = true, desc = 'Deshacer con Backspace' })
vim.keymap.set('n', '<Space>', '<C-r>', { noremap = true, desc = 'Rehacer con Space' })

vim.api.nvim_set_keymap("v", "<Space>", "<Esc><C-d>0v", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<BS>", "<Esc><C-u>0v", { noremap = true, silent = true })
    
-- 1. Comando para copiar la ruta completa del archivo actual
vim.api.nvim_create_user_command('CpPath', function()
  local path = vim.fn.expand('%:p')
  vim.fn.setreg('+', path) -- Copia al portapapeles '+' (sistema)
  print("Ruta copiada al portapapeles: " .. path)
end, {})

-- 2. Comando para seleccionar todo el archivo
vim.api.nvim_create_user_command('SelectAll', function()
  -- normal! ggVG equivale a ir al principio y seleccionar hasta el final
  vim.cmd('normal! ggVG')
end, {})
    
local function reset_number_mode()
  -- Lista de teclas que mapeamos
  local keys = {'l', 'k', 'j', 'p', 'o', 'u', 'n', 'm', 'b', 'g', 'a'}
  for _, key in ipairs(keys) do
    pcall(vim.keymap.del, 'i', key, { buffer = true })
  end
  print("Salio modo numero")
end

local function enable_number_mode()
  -- Mapeos locales al buffer actual (buffer = true)
  local mappings = {
    l = '1', k = '2', j = '3', p = '4', o = '5',
    u = '6', n = '7', m = '8', b = '9', g = '0'
  }

  for key, value in pairs(mappings) do
    vim.keymap.set('i', key, value, { buffer = true })
  end

  -- La tecla 'a' sale del modo y restaura el comportamiento original
  vim.keymap.set('i', 'a', function()
    reset_number_mode()
  end, { buffer = true, desc = 'Salir de modo numero' })

  print("Modo numero activado")
end

-- Atajo para activar el modo
vim.keymap.set('i', '<Tab><BS>', enable_number_mode, { desc = 'Activar modo numero' })    
    
local caps_mode = false
vim.keymap.set("i", "<Tab>-", function()
    if caps_mode == true then
       caps_mode = false 
       print("mayuscula false")
    else 
       caps_mode = true 
       print("mayuscula true")
    end
end, { expr = true })

for c in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
    vim.keymap.set("i", c, function()
        if caps_mode then
            return c:upper()
        end
        return c
    end, { expr = true })
end
