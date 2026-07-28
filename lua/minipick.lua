
vim.keymap.set("v", "k", function()
  MiniPick.start({
    source = {
      name = "Archivos recientes",
      items = vim.v.oldfiles,
    },
  })
end, { desc = "Abrir archivo reciente" })
vim.keymap.set("n", "<CR><BS>", function()
  local ruta ="/home/manuel/Documents/javaProyect/springBoot/demo" 

  local archivos = {}

  for _, file in ipairs(vim.v.oldfiles) do
    if vim.startswith(file, ruta) then
      table.insert(archivos, {
        text = file:sub(#ruta + 1), -- Lo que se muestra
        path = file,                -- Ruta real
      })
    end
  end

  MiniPick.start({
    source = {
      name = "Archivos recientes",
      items = archivos,
    },
  })
end, { desc = "Archivos recientes de una ruta" })
