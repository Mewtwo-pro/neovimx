

local original_buf = nil
local original_win = nil
local input_buf = nil
local input_win = nil
local path_netrw = nil
local path_git_work = nil
local function openBuffer(item_buffer)
  vim.api.nvim_set_current_buf(item_buffer)
end
vim.keymap.set("n", "bm", function()
  local items = {}

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr)
      and vim.bo[bufnr].buflisted
      and vim.api.nvim_buf_is_loaded(bufnr) then

      local name = vim.api.nvim_buf_get_name(bufnr)

      if name == "" then
        name = "[No Name]"
      else
        name = vim.fn.fnamemodify(name, ":.")
      end

      table.insert(items, {
        text = string.format("%d: %s", bufnr, name),
        bufnr = bufnr,
      })
    end
  end

  MiniPick.start({
    source = {
      name = "Buffers Abiertos",
      items = items,

      choose = function(item)
        if item then
            vim.schedule(function()
               openBuffer(item.bufnr)
            end)
        end
      end,
    },
  })
end, { desc = "Listar y cambiar entre buffers abiertos" })
local function go_grep(item)
          -- Abrir archivo
          vim.cmd.edit(vim.fn.fnameescape(item.path))

          -- Ir a la línea encontrada
          vim.api.nvim_win_set_cursor(0, {
            item.lnum,
            item.col - 1,
          })

          -- Centrar
          vim.cmd('normal! zz')
end
local function grep_filter(dir)
    local current_dir = dir
    local line = vim.api.nvim_get_current_line()
    local pattern = line:gsub("^name:%s*", "")
    if pattern == "" then return end
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })

    -- Ejecutar grep recursivamente
    local result = vim.fn.systemlist({
      'grep',
      '-rn',
      '-i',
      '--',
      pattern,
      current_dir,
    })

    -- Si no hay resultados
    if #result == 0 then
      vim.notify(
        'No se encontraron coincidencias',
        vim.log.levels.INFO
      )
      return
    end

    local items = {}

    for _, line in ipairs(result) do

      -- Formato grep:
      -- archivo:linea:contenido
      local filename, lnum, text =
        line:match('^(.-):(%d+):(.*)$')

      if filename and lnum then

        lnum = tonumber(lnum)

        table.insert(items, {
          text = string.format(
            '%s  │  %s:%d',
            vim.trim(text),
            vim.fn.fnamemodify(filename, ':.' ),
            lnum
          ),

          path = filename,
          lnum = lnum,
          col = 1,
        })

      end
    end

    -- Mostrar resultados en MiniPick
    MiniPick.start({
      source = {
        name = 'Grep: ' .. pattern,
        items = items,

        choose = function(item)
          if not item then
            return
          end
            vim.schedule(function()
               go_grep(item)
            end)
        end,
      },
    })

end

local function copy_portapapeles(dir)
vim.fn.setreg("+", dir)
vim.notify("Ruta copiada : " .. dir, vim.log.levels.INFO)
end
local function get_search_line()
    local line = vim.api.nvim_get_current_line()
    local input = line:gsub("^name:%s*", "")
    if input == "" then return end
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
    local full_path = path_netrw .. "/" .. input
    local f = io.open(full_path, "w")
    if f then
      f:close()
      vim.cmd("Rexplore")
      vim.cmd("Rexplore")
    end
end
function _G.input_newfile()
    original_buf = vim.api.nvim_get_current_buf()
    original_win = vim.api.nvim_get_current_win()
    input_buf = vim.api.nvim_create_buf(false, true)

    local width, height = 30, 1
    
    local row = vim.o.lines - height - 3
    local col = vim.o.columns - width - 2
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
    vim.fn.prompt_setprompt(input_buf, "name: ")
    
    -- Space → buscar y cerrar
    vim.keymap.set("i", "<Space>", function()
        get_search_line()
    end, { buffer = input_buf })

    -- Programar el ingreso al modo inserción para después de que mini.pick cierre sus ventanas
    vim.schedule(function()
        vim.api.nvim_set_current_win(input_win)
        vim.cmd("startinsert")
    end)
end
    
function _G.input_grep(dir)
    original_buf = vim.api.nvim_get_current_buf()
    original_win = vim.api.nvim_get_current_win()
    input_buf = vim.api.nvim_create_buf(false, true)

    local width, height = 30, 1
    
    local row = vim.o.lines - height - 3
    local col = vim.o.columns - width - 2
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
    vim.fn.prompt_setprompt(input_buf, "name: ")
    
    -- Space → buscar y cerrar
    vim.keymap.set("i", "<CR>", function()
        grep_filter(dir)
    end, { buffer = input_buf })

    -- Programar el ingreso al modo inserción para después de que mini.pick cierre sus ventanas
    vim.schedule(function()
        vim.api.nvim_set_current_win(input_win)
        vim.cmd("startinsert")
    end)
end
    
vim.api.nvim_set_keymap("v", "x", "<Esc>:Ex<CR>", {
  noremap = true,
  silent = true,
})

vim.g.netrw_banner = 0

    
local function seleccionar_task()
    local dir = vim.b.netrw_curdir
    if not dir then
        return
    end

    local play_json = dir .. "/play.json"

    if vim.fn.filereadable(play_json) == 0 then
        vim.notify("No existe play.json")
        return
    end

    local contenido = table.concat(vim.fn.readfile(play_json), "\n")
    local datos = vim.json.decode(contenido)

    local items = {}

    for k in pairs(datos) do
        table.insert(items, k)
    end

    table.sort(items)

    MiniPick.start({
        source = {
            name = "Play",
            items = items,
            choose = function(item)
                local elegido = datos[item]

                local task_path = "/home/manuel/.config/nvim/lua/task.json"

                local task = {}

                if vim.fn.filereadable(task_path) == 1 then
                    task = vim.json.decode(
                        table.concat(vim.fn.readfile(task_path), "\n")
                    )
                end

                task.play = elegido.play
                task.path = elegido.path
                task.cmd = elegido.cmd

                vim.fn.writefile(
                    vim.split(vim.json.encode(task), "\n"),
                    task_path
                )

                vim.notify("Task actualizado")
            end,
        },
    })
end
local function git_reset_all()
    local cwd = path_git_work
    cwd = vim.trim(cwd)
    -- Si no especificas archivos, por defecto hace git reset de todo ("")
    local target_files = ""

    local cmd = { "git", "reset" }
    if target_files ~= "" then
        table.insert(cmd, target_files)
    end

    local success, obj = pcall(function()
        return vim.system(cmd, {
            cwd = cwd,
            text = true,
        }):wait()
    end)

    if not success or obj.code ~= 0 then
        local err_msg = (obj and obj.stderr) or "Error desconocido"
        vim.notify("Error al hacer git reset: " .. vim.trim(err_msg), vim.log.levels.WARN)
        return false
    end

    vim.notify("Archivos desmarcados (git reset) con éxito.", vim.log.levels.INFO)
    return true
end
local function git_add(files)
    local cwd = path_git_work 
    cwd = vim.trim(cwd)   
    local target_files = files
    if files == "nil" then
       target_files = "." 
    end
    -- Ejecutamos 'git add <archivos>'
    local obj = vim.system({ "git", "add", target_files }, {
        cwd = cwd,
        text = true,
    }):wait()

    if obj.code == 0 then
        vim.notify("Archivos agregados a Git con éxito.", vim.log.levels.INFO)
        return true
    else
        local err_msg = (obj.stderr and obj.stderr ~= "") and obj.stderr or obj.stdout
        vim.notify("Error al hacer git add: " .. vim.trim(err_msg), vim.log.levels.WARN)
        return false
    end
end   
local function get_git_root(local_path)
    local cwd = local_path
    
    -- Ejecutamos el comando y capturamos el resultado y el código de salida
    local handle = io.popen("git -C " .. vim.fn.shellescape(cwd) .. " rev-parse --show-toplevel 2>/dev/null")
    
    if not handle then
        vim.notify("Error al ejecutar el comando de Git", vim.log.levels.ERROR)
        return nil
    end

    local result = handle:read("*a")
    handle:close()

    if result and result ~= "" then
        path_git_work = result
    else
        vim.notify("El directorio no es un repositorio de Git", vim.log.levels.WARN)
        return nil
    end
end
vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function(args)
    local opts = {
      buffer = args.buf,
      silent = true,
      noremap = true,
    }

    -- Tus atajos anteriores
    vim.keymap.set("n", "q", "<cmd>q<CR>", opts)
    vim.keymap.set("n", "p", "k", opts) 
    vim.keymap.set("n", "o", "j", opts) 

    -- NUEVO: Atajo (por ejemplo, la tecla '<leader>m' o la que prefieras) para abrir un menú de acciones con mini.pick
    vim.keymap.set("n", "a", function()
      -- Obtener la ruta del archivo o directorio actual bajo el cursor en netrw
-- Obtener la ruta del archivo o directorio actual bajo el cursor en netrw de forma segura
local cfile = vim.fn.expand("<cfile>")
local curdir = vim.b.netrw_curdir or vim.fn.expand("%:p:h")
local target_path = curdir .. "/" .. cfile
      -- Definir las acciones disponibles en mini.pick
local acciones = {
  { text = "Crear nuevo archivo aquí", action = "create_file" },
  { text = "Eliminar: " .. cfile, action = "delete", path = target_path },
  { text = "git add : " .. cfile, action = "gitadd", path = target_path },
  { text = "git add : '.' ", action = "gitaddall", path = target_path },
  { text = "git reset all ", action = "gitRemoveAll", path = target_path },
  { text = "set play compiler", action = "playcmd" },
  { text = "copy path", action = "copypath" },
  { text = "grep", action = "grepcmd" },
}
      MiniPick.start({
        source = {
          name = "Acciones Netrw",
          items = acciones,
          -- Función que se ejecuta al presionar Enter sobre una opción
          choose = function(item)
            if not item then return end

            if item.action == "create_file" then
              -- Pedir el nombre del nuevo archivo mediante un prompt
              path_netrw = curdir 
              _G.input_newfile()
            
            elseif item.action == "gitRemoveAll" then
                vim.schedule(function()
                   get_git_root(curdir)
                   git_reset_all()
                end)
            elseif item.action == "gitadd" then
                vim.schedule(function()
                   get_git_root(curdir)
                   git_add(cfile)
                end)
            elseif item.action == "gitaddall" then
                vim.schedule(function()
                   get_git_root(curdir, "nil")
                end)
            elseif item.action == "grepcmd" then
                vim.schedule(function()
                   _G.input_grep(curdir)
                end)
            elseif item.action == "playcmd" then
                vim.schedule(function()
                   seleccionar_task(curdir)
                end)
            elseif item.action == "copypath" then
                vim.schedule(function()
                   copy_portapapeles(target_path) 
                end)
            elseif item.action == "delete" then
              -- Confirmar eliminación
              vim.ui.select({ "Sí", "No" }, { prompt = "¿Eliminar " .. cfile .. "?" }, function(choice)
                if choice == "Sí" then
                  -- Eliminar archivo o directorio (usa vim.fn.delete)
                  local success = vim.fn.delete(item.path, "rf")
                  if success == 0 then
                    print("Eliminado con éxito")
                    -- Refrescar netrw
                    vim.cmd("Rexplore")
                    vim.cmd("Rexplore")
                  else
                    print("No se pudo eliminar el archivo/carpeta")
                  end
                end
              end)
            end
          end,
        },
      })
    end, opts)
  end,
})
-- regex_custom

vim.keymap.set("n", "b<Space>", function()
    local archivo = vim.fn.stdpath("config") .. "/lua/code.txt"

    local contenido = vim.fn.readfile(archivo)

    vim.api.nvim_put({""}, "l", true, true)
    vim.api.nvim_put(contenido, "c", true, true)
end)
vim.keymap.set("n", "b<Backspace>", function()
    local script = vim.fn.stdpath("config") .. "/lua/miRegex.py"

    vim.system({
        "python3",
        script
    })
end)
