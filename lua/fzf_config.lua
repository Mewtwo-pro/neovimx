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

-- Atajos de teclado
--[[
vim.keymap.set("n", "ku", function()
  -- Obtener el contenido del portapapeles (registro "+)
  local clipboard = vim.fn.getreg("+")
  -- Abrir live_grep con ese texto ya en el prompt
  require("fzf-lua").live_grep({ search = clipboard })
end, { desc = "Grep en proyecto con portapapeles" })
]]
vim.keymap.set("v", "g", fzf.buffers, { desc = "Buffers abiertos" })
vim.keymap.set("v", "k", fzf.oldfiles, { desc = "Archivos recientes" })
--[[
vim.keymap.set("n", "kj", function()
  require("fzf-lua").files({ cwd = "~" })
end, { desc = "Buscar archivos desde HOME" })
vim.keymap.set("n", "kk", function()
  require("fzf-lua").live_grep({ cwd = "~" })
end, { desc = "Grep desde HOME" })

vim.keymap.set("n", "ky", function()
  require("fzf-lua").files({
    cwd = vim.fn.expand("%:p:h"), -- carpeta del buffer actual
  })
end, { desc = "Buscar archivos en carpeta del buffer" })

vim.keymap.set("n", "kl", function()
  require("fzf-lua").live_grep({
    cwd = vim.fn.expand("%:p:h"), -- carpeta del buffer actual
  })
end, { desc = "Grep en carpeta del buffer" })
]]
