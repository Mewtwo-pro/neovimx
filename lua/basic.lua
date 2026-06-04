vim.opt.foldmethod = 'indent'
vim.cmd("colorscheme wildcharm")
vim.opt.fillchars = "fold: "
sdsvim.opt.foldtext = "getline(v:foldstart)"
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
vim.opt.hlsearch = false
-- Aplica la indentación capturada a la línea actual
function ApplyIndent()
  local line = vim.api.nvim_get_current_line()
  local new_line = indent_cache .. line:gsub("^%s*", "")
  vim.api.nvim_set_current_line(new_line)
end 

vim.api.nvim_set_keymap('n','a', 'i', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','gh', 'G', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','i', 'v', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v','n', '<Esc>:q!<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i',';', '<Esc>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'g<Space>', ':', { noremap = true})
vim.api.nvim_set_keymap('n','q', 'zo', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','n', 'viw', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v','q', '<Esc>zR', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n','z', 'zc', {noremap = true, silent = true })
vim.api.nvim_set_keymap('v','z', '<Esc>zM', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v','c', '<Esc>:q!<CR>', { noremap = true, silent = true })
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
vim.keymap.set("i", "<Tab><Space>", "<Esc>:call append(line('.'), repeat(' ', indent('.')))<CR>ja<Tab>", { noremap = true, silent = true })
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
vim.api.nvim_set_keymap('i','<Tab>o', '@', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>u', ';', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>l', "''<Left>", { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>g', '{}<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>j', '``<Left>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>q', '#', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>y', '%', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i','<Tab>h', '?', { noremap = true, silent = true })

vim.api.nvim_set_keymap('i','<Tab>k', '_', { noremap = true, silent = true })

vim.keymap.set('n', '<BS>', 'u', { noremap = true, desc = 'Deshacer con Backspace' })
vim.keymap.set('n', '<Space>', '<C-r>', { noremap = true, desc = 'Rehacer con Space' })
-- modal 
local function reset_default()
  vim.keymap.set('n', '<BS>', 'u', { noremap = true, desc = 'Deshacer con Backspace' })
  vim.keymap.set('n', '<Space>', '<C-r>', { noremap = true, desc = 'Rehacer con Space' })
  print("reset")
end

vim.api.nvim_set_keymap("v", "<Space>", "<Esc><C-d>v", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<BS>", "<Esc><C-u>v", { noremap = true, silent = true })
    
vim.keymap.set({'n', 'v'}, ';', function()
  reset_default()
end, { noremap = true, silent = true, desc = 'Ejecutar reset_default' })

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
vim.api.nvim_command('cabbrev copypath CpPath')
vim.api.nvim_command('cabbrev selectall SelectAll')
