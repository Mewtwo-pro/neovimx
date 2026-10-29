local function reset_default()
  vim.keymap.set('n', '<BS>', 'u', { noremap = true, desc = 'Deshacer con Backspace' })
  vim.keymap.set('n', '<Space>', '<C-r>', { noremap = true, desc = 'Rehacer con Space' })
  vim.cmd("noh")
  print("reset")
end
    
vim.keymap.set('n', ';', function()
      reset_default()
end, { noremap = true, silent = true, desc = 'Ejecutar reset_default' })
    
    
vim.keymap.set('v', ';', function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
      reset_default()
end, { noremap = true, silent = true, desc = 'Ejecutar reset_default' })
    
        

