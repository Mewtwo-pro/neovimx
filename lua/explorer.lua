-- 0 oculta la cabecera, 1 la muestra
vim.g.netrw_banner = 0
-- Creamos un grupo pa los autocomandos de netrw
local netrw_group = vim.api.nvim_create_augroup("MiNetrwConfig", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  group = netrw_group,
  callback = function()
    -- nnoremap <buffer> ... en Lua:
    local opts = { buffer = true, noremap = true, silent = true }
    
    vim.keymap.set('n', 'q', ':q<CR>', opts)
    vim.keymap.set('n', 'o', '<Down>', opts)
    vim.keymap.set('n', 'p', 'k', opts)
    vim.keymap.set('n', 'a', function() 
      print(vim.fn.expand('%:p:h')) 
    end, opts)
  end,
})
    
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
        
