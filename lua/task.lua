local input_buf, input_win
local term_buf, term_win, term_job
local function formatear_json(tabla)
    local json = vim.json.encode(tabla)

    local resultado = vim.fn.system(
        { "python3", "-m", "json.tool" },
        json
    )

    if vim.v.shell_error ~= 0 then
        return json -- si falla, devolver el JSON compacto
    end

    return resultado
end
    
local mis_task = { "python","sfml" , "java"}
-- Registramos la función de completado globalmente para que vim.fn.input la encuentre
_G.mi_completado_task= function(ArgLead, CmdLine, CursorPos)
  -- Aquí reutilizamos la lógica de filtrado
  local comandos = mis_task 
  local matches = {}
  for _, v in ipairs(comandos) do
    if v:lower():match("^" .. ArgLead:lower()) then
      table.insert(matches, v)
    end
  end
  return matches
end
-- get current task 
local function set_current_task()
  -- Definimos la lista de tus comandos personalizados
  local comandos_disponibles = mis_task 
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
    prompt = "select task : ",
    completion = "customlist,v:lua.mi_completado_task", -- Usamos un callback global
  })

  -- Ejecutamos el comando si existe
  if comando_elegido ~= "" then
        
      local json_path = "/home/manuel/.config/nvim/lua/task.json"
      if vim.fn.filereadable(json_path) == 0 then
        vim.notify("errro el json no exise", vim.log.levels.ERROR)
        return
      end
      local file = io.open(json_path, "r")
      if not file then return end
      local content = file:read("*a")
      file:close()
      local status_decode , decoded = pcall(vim.json.decode, content)
      if not status_decode then
        vim.notify("error : json invalido , no se pudo leer", vim.log.levels.ERROR)
        return
      end
      decoded["current"] = comando_elegido 
         
      local json_bonito = formatear_json(decoded)
      local write_file = io.open(json_path, "w")
      if not write_file then
        vim.notify("error : no se pude abrir el archivo para escribir", vim.log.levels.ERROR)
        return
      end
      write_file:write(json_bonito)
      write_file:close()
      vim.notify("json actualizado con exito !", vim.log.levels.INFO)
  end
end

vim.api.nvim_create_user_command(
    'Taskselect',
    function()
        set_current_task()
    end,
    {}
)    
    
-- ========================
-- Abrir terminal flotante
-- ========================
local function open_terminal()
  term_buf = vim.api.nvim_create_buf(false, true)

  term_win = vim.api.nvim_open_win(term_buf, false, {
    relative = "editor",
    width = 90,
    height = 18,
    row = 2,
    col = 5,
    style = "minimal",
    border = "rounded",
  })

  vim.api.nvim_win_call(term_win, function()
    term_job = vim.fn.termopen("bash", {
      on_exit = function()
        vim.schedule(function()
          if term_win and vim.api.nvim_win_is_valid(term_win) then
            vim.api.nvim_win_close(term_win, true)
          end
        end)
      end
    })

    -- opciones visuales
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.bo.buflisted = false
    vim.bo.filetype = "terminal"
  end)
end

-- ========================
-- Scroll al final
-- ========================
local function scroll_term_bottom()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    local line_count = vim.api.nvim_buf_line_count(term_buf)
    vim.api.nvim_win_set_cursor(term_win, {line_count, 0})
  end
end
local path_filex = nil
local cmd = nil
local play_cmd = nil 
local function get_json_data()
    local json_path = "/home/manuel/.config/nvim/lua/task.json"
        
    if vim.fn.filereadable(json_path) == 0 then
        vim.notify("erro : el archivo json no existe en" .. json_path , vim.log.levels.ERROR)
        return 
    end
        
    local file = io.open(json_path, "r")
    if not file then return end 
    local content = file:read("*a")
    file:close()
    
    local status, decoded = pcall(vim.json.decode, content)
    if not status then
        vim.notify("error: el archivo json no es valido " , vim.log.levels.ERROR)
        return
    end
    if decoded then 
                
        local current_task = decoded["current"]
        local mi_task = decoded[current_task]
        path_filex = mi_task.path 
        cmd = mi_task.cmd 
        play_cmd = mi_task.play
    else 
        vim.notify(" la clave 'nombre' no existe", vim.log.levels.WARN)
    end
end
-- ========================
-- Enviar comando
-- ========================
local function send_cmd()
  get_json_data()
  vim.api.nvim_chan_send(term_job,
    "cd " .. path_filex .. " && " .. cmd .. "\n"
  )
  vim.defer_fn(scroll_term_bottom, 60)
end

local function play_app()
  vim.api.nvim_chan_send(term_job,
    "cd " .. path_filex .. " && " .. play_cmd .. "\n"
  )
  vim.defer_fn(scroll_term_bottom, 60)
end
-- ========================
-- Cerrar todo
-- ========================
local function close_inputx()
  if input_win and vim.api.nvim_win_is_valid(input_win) then
    vim.api.nvim_win_close(input_win, true)
  end

  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_close(term_win, true)
  end
end
    
local function view_init_error()
    vim.api.nvim_set_current_win(term_win)
    local pal_buscar = "@manuel"
    vim.fn.feedkeys("?\\c" .. vim.fn.escape(pal_buscar, "/\\") .. "\n", "n")
end 
    
_G.error_linea = 1 
local function buscar_primera_cpp()
  vim.api.nvim_win_call(term_win, function()
    vim.api.nvim_win_set_cursor(0, {1, 0})

    local lnum = vim.fn.search("\\.cpp:", "c")

    if lnum == 0 then
      print("No se encontró '.cpp:'")
    else
      print("Encontrado en línea: " .. lnum)

      -- 🔥 Obtener texto real de la línea
      local texto = vim.api.nvim_get_current_line()

      -- Extraer número
      local num = texto:match("%.cpp:(%d+)")

      if num then
        error_linea = num
        close_inputx() 
        vim.cmd(error_linea)         
      else
        print("No se encontró número después de .cpp:")
      end
    end
  end)
end
function input_run_compile()
  _G.path_filex = vim.fn.expand("%:p:h")

  open_terminal()

  input_buf = vim.api.nvim_create_buf(false, true)

  input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = 45,
    height = 1,
    row = vim.o.lines - 4,
    col = 2,
    style = "minimal",
    border = "rounded",
  })
  send_cmd()
  vim.bo[input_buf].buftype = "prompt"
  vim.fn.prompt_setprompt(input_buf,
    "Git init? (Space=Yes / Enter=Exit): "
  )

  vim.keymap.set("n", "x", function()
    buscar_primera_cpp()
  end, {buffer = input_buf})

  vim.keymap.set("n", "z", function()
    play_app()
  end, {buffer = input_buf})

  vim.keymap.set("n", "<Space>", function()
    view_init_error()
  end, {buffer = input_buf})

  vim.keymap.set("n", "<CR>", function()
    close_inputx()
  end, {buffer = input_buf})
end

vim.keymap.set("n", "h", function()
    input_run_compile()
  end, {buffer = input_buf})
    
-- formatear un archivo json con el comando :       
--:%!python3 -m json.tool
--
--vim.api.nvim_set_keymap('v','y', '<Esc>:lua _G.input_git_net()<CR>', { noremap = true, silent = true })
