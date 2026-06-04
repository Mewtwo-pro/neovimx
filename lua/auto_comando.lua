    
local mis_comandos = { "CpPath","SelectAll"}
local function ejecutar_comando_con_input()
  -- Definimos la lista de tus comandos personalizados
  local comandos_disponibles = mis_comandos
  -- Definimos la función de completado (custom completion)
  local function completado(ArgLead, CmdLine, CursorPos)
    local coincidencias = {}
    local patron = ArgLead:lower() -- Convertimos a minúscula para ignorar mayúsculas
    
    for _, cmd in ipairs(comandos_disponibles) do
      if cmd:lower():find(patron, 1, true) then
        table.insert(coincidencias, cmd)
      end
    end
    return coincidencias
  end

  -- Pedimos el input al usuario
  local comando_elegido = vim.fn.input({
    prompt = "Ejecutar comando: ",
    completion = "customlist,v:lua.mi_completado_func", -- Usamos un callback global
  })

  -- Ejecutamos el comando si existe
  if comando_elegido ~= "" then
    vim.cmd(comando_elegido)
  end
end

-- Registramos la función de completado globalmente para que vim.fn.input la encuentre
_G.mi_completado_func = function(ArgLead, CmdLine, CursorPos)
  -- Aquí reutilizamos la lógica de filtrado
  local comandos = mis_comandos
  local matches = {}
  for _, v in ipairs(comandos) do
    if v:lower():match("^" .. ArgLead:lower()) then
      table.insert(matches, v)
    end
  end
  return matches
end

vim.keymap.set('n', '<CR>', ejecutar_comando_con_input, { desc = "Ejecutar comando con autocompletado" })
