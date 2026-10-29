local input_buf = nil
local input_win = nil
local term_buf = nil 
local term_win = nil 
local term_job = nil

 -- ========================
-- Autocompletar exclusivamente directorios (carpetas)
-- ========================
local function completar_carpeta_terminal()
  -- 1. Obtener el directorio de trabajo actual (CWD) de la terminal superior
  local base_dir = vim.uv.cwd()
  if term_job then
    local pid = vim.fn.jobpid(term_job)
    if pid and pid > 0 then
      local link = vim.uv.fs_readlink("/proc/" .. pid .. "/cwd")
      if link then
        base_dir = link
      end
    end
  end

  -- 2. Detectar la palabra/ruta bajo el cursor en el input
  local linea = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  local inicio, fin
  local pos = 1
  while true do
    local s, e = linea:find("%S+", pos)
    if not s then break end
    if col >= s - 1 and col <= e then
      inicio, fin = s, e
      break
    end
    pos = e + 1
  end

  if not inicio then
    vim.notify("No se detectó ningún texto.", vim.log.levels.WARN)
    return
  end

  local term = linea:sub(inicio, fin)

  -- 3. Separar la ruta de directorios y el término a buscar
  local sub_dir = term:match("^(.*)/[^/]*$")
  local limpio = term:match("[^/]+$") or term

  -- Resolver la ruta de búsqueda en el disco (soporte para ~ y rutas absolutas/relativas)
  local ruta_busqueda = base_dir
  if sub_dir then
    local sub_expandido = sub_dir
    if vim.startswith(sub_expandido, "~") then
      sub_expandido = sub_expandido:gsub("^~", vim.uv.os_homedir())
    end

    if vim.startswith(sub_expandido, "/") then
      ruta_busqueda = sub_expandido
    else
      ruta_busqueda = base_dir .. "/" .. sub_expandido
    end
  end

  -- 4. Buscar exclusivamente directorios (-type d) con find
  local patron = "*" .. limpio .. "*"
  local cmd = string.format(
    "find %s -maxdepth 1 -type d -iname %s 2>/dev/null",
    vim.fn.shellescape(ruta_busqueda),
    vim.fn.shellescape(patron)
  )

  local handle = io.popen(cmd)
  if not handle then return end
  local output = handle:read("*a")
  handle:close()

  local resultados = {}
  for carpeta in output:gmatch("[^\r\n]+") do
    -- Opcional: ignorar el directorio actual "." que devuelve find por defecto
    local nombre = vim.fs.basename(carpeta)
    if nombre ~= "" and nombre ~= "." and carpeta ~= ruta_busqueda then
      table.insert(resultados, nombre)
    end
  end

  -- Función auxiliar para construir la ruta final añadiendo una barra "/" al final
  local function construir_ruta_final(nombre_carpeta)
    local base_parcial = sub_dir and (sub_dir .. "/" .. nombre_carpeta) or nombre_carpeta
    return base_parcial .. "/"
  end

  -- 5. Manejar resultados (una sola coincidencia o mini.pick)
  if #resultados == 1 then
    local ruta_final = construir_ruta_final(resultados[1])

    vim.api.nvim_buf_set_text(
      0,
      vim.api.nvim_win_get_cursor(0)[1] - 1,
      inicio - 1,
      vim.api.nvim_win_get_cursor(0)[1] - 1,
      fin,
      { ruta_final }
    )
  elseif #resultados > 1 then
    table.sort(resultados)
    local MiniPick = require("mini.pick")
    local bufnr = vim.api.nvim_get_current_buf()
    local fila = vim.api.nvim_win_get_cursor(0)[1] - 1
    local col_inicio = inicio - 1
    local col_fin = fin

    MiniPick.start({
      source = {
        name = "Carpetas (" .. (sub_dir and sub_dir or ".") .. ")",
        items = resultados,
        choose = function(item)
          if not item then return end
          local ruta_final = construir_ruta_final(item)
          vim.api.nvim_buf_set_text(bufnr, fila, col_inicio, fila, col_fin, { ruta_final })
        end,
      },
    })
  else
    vim.notify("No se encontraron carpetas en: " .. ruta_busqueda, vim.log.levels.WARN)
  end
end   
-- Autocompletar con soporte para subcarpetas y tilde (~)
local function completar_archivo_terminal()
  -- 1. Obtener el directorio de trabajo actual (CWD) de la terminal superior
  local base_dir = vim.uv.cwd()
  if term_job then
    local pid = vim.fn.jobpid(term_job)
    if pid and pid > 0 then
      local link = vim.uv.fs_readlink("/proc/" .. pid .. "/cwd")
      if link then
        base_dir = link
      end
    end
  end

  -- 2. Detectar la palabra/ruta bajo el cursor en el input
  local linea = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]

  local inicio, fin
  local pos = 1
  while true do
    local s, e = linea:find("%S+", pos)
    if not s then break end
    if col >= s - 1 and col <= e then
      inicio, fin = s, e
      break
    end
    pos = e + 1
  end

  if not inicio then
    vim.notify("No se detectó ningún texto.", vim.log.levels.WARN)
    return
  end

  local term = linea:sub(inicio, fin)

  -- 3. Separar la ruta de directorios y el término a buscar
  local sub_dir = term:match("^(.*)/[^/]*$")
  local limpio = term:match("[^/]+$") or term

  -- Resolver la ruta de búsqueda en el disco (soporte para ~ y rutas absolutas/relativas)
  local ruta_busqueda = base_dir
  if sub_dir then
    local sub_expandido = sub_dir
    -- Expandir ~ al directorio HOME del usuario
    if vim.startswith(sub_expandido, "~") then
      sub_expandido = sub_expandido:gsub("^~", vim.uv.os_homedir())
    end

    if vim.startswith(sub_expandido, "/") then
      ruta_busqueda = sub_expandido
    else
      ruta_busqueda = base_dir .. "/" .. sub_expandido
    end
  end

  -- 4. Buscar archivos con find dentro del directorio correspondiente
  local patron = "*" .. limpio .. "*"
  local cmd = string.format(
    "find %s -maxdepth 1 -type f -iname %s 2>/dev/null",
    vim.fn.shellescape(ruta_busqueda),
    vim.fn.shellescape(patron)
  )

  local handle = io.popen(cmd)
  if not handle then return end
  local output = handle:read("*a")
  handle:close()

  local resultados = {}
  for archivo in output:gmatch("[^\r\n]+") do
    table.insert(resultados, vim.fs.basename(archivo))
  end

  -- Función auxiliar para construir la ruta final preservando lo que el usuario escribió (incluyendo ~)
  local function construir_ruta_final(nombre_archivo)
    if sub_dir and sub_dir ~= "" then
      return sub_dir .. "/" .. nombre_archivo
    else
      return nombre_archivo
    end
  end

  -- 5. Manejar resultados (una sola coincidencia o mini.pick)
  if #resultados == 1 then
    local ruta_final = construir_ruta_final(resultados[1])

    vim.api.nvim_buf_set_text(
      0,
      vim.api.nvim_win_get_cursor(0)[1] - 1,
      inicio - 1,
      vim.api.nvim_win_get_cursor(0)[1] - 1,
      fin,
      { ruta_final }
    )
  elseif #resultados > 1 then
    table.sort(resultados)
    local MiniPick = require("mini.pick")
    local bufnr = vim.api.nvim_get_current_buf()
    local fila = vim.api.nvim_win_get_cursor(0)[1] - 1
    local col_inicio = inicio - 1
    local col_fin = fin

    MiniPick.start({
      source = {
        name = "Archivos (" .. (sub_dir and sub_dir or ".") .. ")",
        items = resultados,
        choose = function(item)
          if not item then return end
          local ruta_final = construir_ruta_final(item)
          vim.api.nvim_buf_set_text(bufnr, fila, col_inicio, fila, col_fin, { ruta_final })
        end,
      },
    })
  else
    vim.notify("No se encontraron archivos en: " .. ruta_busqueda, vim.log.levels.WARN)
  end
end   
-- ========================
-- Abrir terminal flotante (Pantalla Completa / Maximizada)
-- ========================
local function open_terminal()
  term_buf = vim.api.nvim_create_buf(false, true)

  local width = vim.o.columns - 4
  -- Ajustamos la altura de la terminal para dejar espacio exacto al input de 3 líneas
  local height = vim.o.lines - 8

  term_win = vim.api.nvim_open_win(term_buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = 1,
    col = 2,
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
  input_win = nil
  term_win  = nil
end

-- ========================
-- Ejecutar comando libre desde el input
-- ========================
local function ejecutar_comando_libre(linea_texto)
  if linea_texto and linea_texto ~= "" then
    -- Envía el texto a la terminal
    vim.api.nvim_chan_send(term_job, linea_texto .. "\n")
    vim.defer_fn(scroll_term_bottom, 60)
  end
end

-- ========================
-- Interfaz principal
-- ========================
function input_run_compile()
  open_terminal()

  input_buf = vim.api.nvim_create_buf(false, true)

  local input_width = vim.o.columns - 4

  -- Posicionamos el input inferior para que encaje perfectamente con la terminal
  input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = input_width,
    height = 3,
    row = vim.o.lines - 6,
    col = 2,
    style = "minimal",
    border = "rounded",
  })

  -- Configuración de búfer libre sin prompt
  vim.bo[input_buf].buftype = ""
  vim.bo[input_buf].swapfile = false

  -- Entrar en modo inserción
  vim.cmd("startinsert")

  -- Tecla para salir con Escape
  vim.keymap.set("n", "<ESC>", function()
    close_inputx()
  end, {buffer = input_buf})
  
  vim.keymap.set("i", "<ESC>", function()
    close_inputx()
  end, {buffer = input_buf})

  vim.keymap.set("i", "1", function()
    completar_archivo_terminal()
  end, {buffer = input_buf})
  vim.keymap.set("i", "`", function()
    completar_carpeta_terminal()
  end, {buffer = input_buf})
  -- Tecla F2: Envía únicamente la línea actual donde está el cursor
  vim.keymap.set({"n", "i"}, "<Del>", function()
    local mode = vim.api.nvim_get_mode().mode
    if mode:match("^i") then
      vim.cmd("stopinsert")
    end

    local current_line = vim.api.nvim_get_current_line()
    ejecutar_comando_libre(current_line)

    vim.cmd("startinsert")
  end, {buffer = input_buf})

  vim.keymap.set("i", "<F5>", function()
    vim.cmd('normal! hviw"+y')
    local buscFile = "~/.config/nvim/lua/buscardir.sh"
    ejecutar_comando_libre(buscFile)
    vim.cmd('normal! viwd')
    vim.cmd('startinsert')
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(" ", true, false, true), "n", true) 
  end, {buffer = input_buf})
end
local function completar_ruta_lua()
    local linea = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    local antes = linea:sub(1, col)
    local term = antes:match("([^%s]+)$") or ""
    term = vim.fn.trim(term)

    vim.notify("Ruta detectada: [" .. term .. "]")
    local ruta_base = ""
    local limpio = ""
    local ruta_expandida = ""

    -- 2. Detectar si la ruta tiene directorios o barras
    if term:match("/") then
        ruta_base = term:match("^(.*)/[^/]*$")
        limpio = term:match("[^/]+$") or ""
        
        -- Expandir '~' si la ruta empieza con él
        if vim.startswith(ruta_base, "~") then
            local home = vim.uv.os_homedir() or os.getenv("HOME")
            ruta_expandida = ruta_base:gsub("^~", home)
        else
            ruta_expandida = ruta_base
        end
    else
        ruta_base = ""
        limpio = term
        ruta_expandida = "."
    end

    -- 3. Buscar directorios usando find (respeta -iname para ignorar mayúsculas/minúsculas)
    local cmd = string.format("find %s -maxdepth 1 -type d -iname '*%s*' ! -path '%s' 2>/dev/null", 
        vim.fn.shellescape(ruta_expandida), 
        limpio, 
        vim.fn.shellescape(ruta_expandida)
    )

    local handle = io.popen(cmd)
    if not handle then return end
    local output = handle:read("*a")
    handle:close()

    -- 4. Procesar resultados
    local resultados = {}
    for line in output:gmatch("[^\r\n]+") do
        local nombre_carpeta = line:match("^.+/(.+)$") or line
        if nombre_carpeta ~= "" and nombre_carpeta ~= "." then
            table.insert(resultados, nombre_carpeta)
        end
    end

    local total = #resultados

    -- 5. Manejar coincidencias

    if total == 1 then
        local r = resultados[1]
        local resultado_final

        if ruta_base ~= "" then
            resultado_final = ruta_base .. "/" .. r .. "/"
        else
            resultado_final = r .. "/"
        end

        -- Reemplazar el texto original de la ruta
        local bufnr = vim.api.nvim_get_current_buf()
        local fila = vim.api.nvim_win_get_cursor(0)[1] - 1
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local antes = linea:sub(1, col)
        local inicio = antes:find("%S+[^%s]*$")

        if inicio then
            vim.api.nvim_buf_set_text(
                bufnr,
                fila,
                inicio - 1,
                fila,
                col,
                { resultado_final }
            )
        end

    elseif total == 0 then
        vim.notify(
            "No se encontraron coincidencias para '" .. term .. "'.",
            vim.log.levels.WARN
        )

    else
        -- Guardar la posición original antes de abrir MiniPick
        local bufnr = vim.api.nvim_get_current_buf()
        local fila = vim.api.nvim_win_get_cursor(0)[1] - 1
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local antes = linea:sub(1, col)
        local inicio = antes:find("%S+[^%s]*$")

        if not inicio then return end

        local col_inicio = inicio - 1
        local col_fin = col

        table.sort(resultados)

        local MiniPick = require("mini.pick")

        MiniPick.start({
            source = {
                name = "Seleccionar carpeta",
                items = resultados,

                choose = function(item)
                    if not item then return end

                    local ruta_final

                    if ruta_base ~= "" then
                        ruta_final = ruta_base .. "/" .. item .. "/"
                    else
                        ruta_final = item .. "/"
                    end

                    vim.api.nvim_buf_set_text(
                        bufnr,
                        fila,
                        col_inicio,
                        fila,
                        col_fin,
                        { ruta_final }
                    )
                end,
            },
        })
    end
end

vim.keymap.set("n", "<CR>t", input_run_compile, {
    desc = "mi_terminal"
})
-- Mapeo en modo Insertar (puedes cambiar '<C-x>p' por el atajo que prefieras)
vim.keymap.set("i", "`", completar_ruta_lua, {
    desc = "Completar ruta inteligente"
})


local function completar_archivo_lua()
    local linea = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    -- Obtener la palabra/ruta completa bajo el cursor
    local inicio, fin
    local pos = 1

    while true do
        local s, e = linea:find("%S+", pos)
        if not s then break end

        if col >= s - 1 and col <= e then
            inicio, fin = s, e
            break
        end

        pos = e + 1
    end

    if not inicio then
        vim.notify("No se detectó ninguna ruta.",
            vim.log.levels.WARN)
        return
    end

    local term = linea:sub(inicio, fin)

    -- Separar directorio y nombre del archivo
    local ruta_base = term:match("^(.*)/[^/]*$")
    local limpio = term:match("[^/]+$") or ""

    local ruta_expandida

    if ruta_base then
        ruta_expandida = ruta_base
        if vim.startswith(ruta_expandida, "~") then
            ruta_expandida = ruta_expandida:gsub(
                "^~", vim.uv.os_homedir()
            )
        end
    else
        ruta_base = ""
        ruta_expandida = "."
    end

    -- Buscar exclusivamente archivos, no directorios
    local patron = "*" .. limpio .. "*"

    local cmd = string.format(
        "find %s -maxdepth 1 -type f -iname %s 2>/dev/null",
        vim.fn.shellescape(ruta_expandida),
        vim.fn.shellescape(patron)
    )

    local handle = io.popen(cmd)
    if not handle then
        vim.notify("No se pudo ejecutar la búsqueda.",
            vim.log.levels.ERROR)
        return
    end

    local output = handle:read("*a")
    handle:close()

    local resultados = {}

    for archivo in output:gmatch("[^\r\n]+") do
        table.insert(resultados, vim.fs.basename(archivo))
    end

    -- Una sola coincidencia: completar
    if #resultados == 1 then
        local resultado = resultados[1]
        local ruta_final

        if ruta_base ~= "" then
            ruta_final = ruta_base .. "/" .. resultado
        else
            ruta_final = resultado
        end

        vim.api.nvim_buf_set_text(
            0,
            vim.api.nvim_win_get_cursor(0)[1] - 1,
            inicio - 1,
            vim.api.nvim_win_get_cursor(0)[1] - 1,
            fin,
            { ruta_final }
        )

    elseif #resultados == 0 then
        vim.notify(
            "No se encontraron archivos para: " .. term,
            vim.log.levels.WARN
        )

    else

        table.sort(resultados)

        local MiniPick = require("mini.pick")

        -- Guardar la posición original para completar después
        local bufnr = vim.api.nvim_get_current_buf()
        local fila = vim.api.nvim_win_get_cursor(0)[1] - 1
        local col_inicio = inicio - 1
        local col_fin = fin

        MiniPick.start({
            source = {
                name = "Seleccionar archivo",
                items = resultados,

                choose = function(item)
                    if not item then return end

                    local ruta_final

                    if ruta_base ~= "" then
                        ruta_final = ruta_base .. "/" .. item
                    else
                        ruta_final = item
                    end

                    -- Reemplazar la ruta original por la seleccionada
                    vim.api.nvim_buf_set_text(
                        bufnr,
                        fila,
                        col_inicio,
                        fila,
                        col_fin,
                        { ruta_final }
                    )
                end,
            },
        })
    end
end

-- F3: completar archivos en modo Insertar
vim.keymap.set("i", "1", completar_archivo_lua, {
    desc = "Completar archivo"
})

vim.keymap.set("i", "7", "<Esc>:", {desc = "Completar archivo"})
