local path_git_work = nil
    
local original_buf = nil
local original_win = nil
local input_buf = nil
local input_win = nil


-- 3. Hacer git push de la rama actual
-- guardar tus credenciales en usuario y password de gitHub
-- git config --global credential.helper store
local function git_push(cwd)
    local rama_actual = vim.fn.system('git -C ' .. vim.fn.shellescape(cwd) .. ' branch --show-current')
    rama_actual = vim.trim(rama_actual)

    if vim.v.shell_error ~= 0 or rama_actual == "" then
        vim.notify("Error al obtener la rama actual.", vim.log.levels.ERROR)
        return
    end

    vim.notify("Haciendo push a origin/" .. rama_actual .."...", vim.log.levels.INFO)

    local push_output = vim.fn.system('git -C ' .. vim.fn.shellescape(cwd) .. ' push -u origin ' .. vim.fn.shellescape(rama_actual))

    if vim.v.shell_error == 0 then
        vim.notify("¡GitHub publicado con éxito!", vim.log.levels.INFO)
    else
        vim.notify("Error al hacer push:\n" .. push_output, vim.log.levels.ERROR)
    end
end

-- 2. Pedir la URL del repositorio mediante un Input
local function git_url(cwd)
    vim.ui.input({
        prompt = 'Link de GitHub : ',
    }, function(input)
        if not input then return end -- Cancelado por el usuario
        
        local clear_name = vim.trim(input)
        if clear_name == "" then return end

        local add_output = vim.fn.system('git -C ' .. vim.fn.shellescape(cwd) .. ' remote add origin ' .. vim.fn.shellescape(clear_name))

        if vim.v.shell_error == 0 then
            git_push(cwd)
        else
            vim.notify("Error al crear remote: " .. add_output, vim.log.levels.ERROR)
        end
    end)
end

-- 1. Verificar si existe 'origin' o pedir URL nueva
local function github_check()
    local cwd = path_git_work
    
    -- Verificar si ya existe un remote 'origin'
    local resultado = vim.fn.system('git -C ' .. vim.fn.shellescape(cwd) .. ' remote get-url origin')
    resultado = vim.trim(resultado)

    if vim.v.shell_error == 0 and resultado ~= "" then
        -- Diálogo modal equivalente usando vim.ui.select
        local mensaje = "El remote 'origin' ya existe:\n" .. resultado .. "\n\n¿Deseas usar este link?"
        
        vim.ui.select({ 'Sí, usar este', 'No, configurar uno nuevo' }, {
            prompt = mensaje,
        }, function(choice)
            if choice == 'Sí, usar este' then
                git_push(cwd)
            elseif choice == 'No, configurar one nuevo' or choice == 'No, configurar uno nuevo' then
                local remove_output = vim.fn.system('git -C ' .. vim.fn.shellescape(cwd) .. ' remote remove origin')
                if vim.v.shell_error == 0 then
                    git_url(cwd)
                else
                    vim.notify("Error al eliminar el remote actual: " .. remove_output, vim.log.levels.ERROR)
                end
            end
        end)
    else
        -- El remoto 'origin' no está configurado
        git_url(cwd)
    end
end

    
local function select_branch(raw_branch)
    if not raw_branch or raw_branch == "" then
        vim.notify("No se proporcionó ninguna rama.", vim.log.levels.WARN)
        return
    end
    local cwd = path_git_work

    -- 1. Limpiar el nombre de la rama
    local selected_branch = raw_branch:gsub("%*", ""):gsub("^%s*(.-)%s*$", "%1")

    if vim.startswith(selected_branch, "remotes/") then
        local parts = vim.split(selected_branch, "/")
        if #parts > 2 then
            selected_branch = parts[#parts]
        end
    end

    -- Función auxiliar para ejecutar comandos de forma segura
    local function run_git_cmd(cmd)
        local full_cmd = string.format("cd %s && %s 2>&1", vim.fn.shellescape(cwd), cmd)
        local handle = io.popen(full_cmd)
        local result = handle:read("*a")
        local success = handle:close()
        return success, vim.trim(result)
    end

    -- Función auxiliar para intentar el switch/checkout de forma estricta
    local function try_switch(branch)
        -- Intentar con git switch
        local success, result = run_git_cmd("git switch " .. vim.fn.shellescape(branch))
        -- Verificamos que realmente haya tenido éxito y que no contenga la palabra "error:" o "Aborting"
        if success and not result:lower():find("error:") and not result:lower():find("aborting") then
            return true, ""
        end

        local res_msg = result

        -- Fallback a git checkout
        local success_co, result_co = run_git_cmd("git checkout " .. vim.fn.shellescape(branch))
        if success_co and not result_co:lower():find("error:") and not result_co:lower():find("aborting") then
            return true, ""
        end

        if result_co ~= "" then
            res_msg = result_co
        end

        return false, res_msg
    end

    -- 2. Primer intento de cambio de rama
    local success, error_msg = try_switch(selected_branch)

    if success then
        vim.notify("Cambiado a la rama: " .. selected_branch, vim.log.levels.INFO)
        return
    end

    -- 3. Manejo de errores por cambios locales o archivos untracked
    if error_msg:find("would be overwritten") or error_msg:find("local changes") or error_msg:find("untracked working tree files") then
        vim.ui.select(
            { "si", "No" },
            {
                prompt = "¿Hay archivos en conflicto o sin rastrear. ¿Deseas hacer un 'stash' y cambiar de rama?",
            },
            function(choice)
                if choice == "si" then
                    -- IMPORTANTE: Para incluir archivos untracked (como animbody.cpp si Git se queja de él), 
                    -- usamos -u (--include-untracked) en el stash.
                    local stash_success, stash_result = run_git_cmd('git stash push -u -m "Auto-stash por Neovim"')

                    if not stash_success then
                        vim.notify("Error al hacer stash:\n" .. stash_result, vim.log.levels.ERROR)
                        return
                    end

                    -- Reintentar switch
                    local retry_success, retry_err = try_switch(selected_branch)
                    if retry_success then
                        -- Aplicar el stash (pop)
                        local pop_success, pop_result = run_git_cmd("git stash pop")

                        if pop_success then
                            vim.notify("¡Cambiado a '" .. selected_branch .. "' y cambios restaurados con éxito!", vim.log.levels.INFO)
                        else
                            vim.notify("Cambiado a " .. selected_branch .. ", pero hubo un conflicto al aplicar el stash:\n" .. pop_result, vim.log.levels.WARN)
                        end
                    else
                        vim.notify("No se pudo cambiar de rama: " .. retry_err, vim.log.levels.ERROR)
                    end
                end
            end
        )
    else
        vim.notify("No se pudo cambiar de rama:\n" .. error_msg, vim.log.levels.ERROR)
    end
end
local function pickGitBranches()
    local file_dir = path_git_work

    -- 3. Obtener la lista de ramas (locales y remotas, limpiando asteriscos y espacios)
    local branch_handle = io.popen(string.format("git -C %s branch -a --format='%%(refname:short)'", vim.fn.shellescape(file_dir)))
    if not branch_handle then return end
    local branch_result = branch_handle:read("*a")
    branch_handle:close()

    local items = {}
    for branch in branch_result:gmatch("[^\r\n]+") do
        branch = branch:gsub("^%s*", ""):gsub("%s*$", "")
        if branch ~= "" then
            table.insert(items, {
                text = branch,
                branch = branch,
            })
        end
    end

    -- 4. Lanzar mini.pick con las ramas encontradas
    MiniPick.start({
        source = {
            name = "Ramas de Git",
            items = items,
            choose = function(item)
                if not item then return end
                print(item.branch)
                select_branch(item.branch) 
            end,
        },
    })
end
--view
local function copyCommitAllFiles(commit_hash)
    -- 1. Obtener la ruta del archivo activo actual para ubicar el repositorio
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file == "" then
        vim.notify("No hay un archivo activo guardado en disco para ubicar el repositorio.", vim.log.levels.WARN)
        return
    end

    local local_path = vim.fn.fnamemodify(current_file, ":h")

    -- 2. Encontrar la raíz del repositorio Git con rev-parse
    local handle = io.popen(string.format("git -C %s rev-parse --show-toplevel", vim.fn.shellescape(local_path)))
    if not handle then return end
    local file_dir = handle:read("*a"):gsub("%s+", "")
    handle:close()

    if file_dir == "" then
        vim.notify("El directorio no pertenece a un repositorio Git.", vim.log.levels.WARN)
        return
    end

    -- 3. Ejecutar el checkout masivo de todo el workspace usando el commit indicado
    local cmd = string.format("git -C %s checkout %s -- .", vim.fn.shellescape(file_dir), vim.fn.shellescape(commit_hash))
    local success, _, stderr = os.execute(cmd)

    if success then
        vim.notify("Workspace completo actualizado con el commit " .. commit_hash:sub(1, 7), vim.log.levels.INFO)
        -- Recargar todos los buffers abiertos en Neovim para que reflejen los cambios en disco
        vim.cmd("checktime")
    else
        vim.notify("Error de Git al actualizar el workspace.", vim.log.levels.ERROR)
    end
end
local function copyCommitCurrentFile(commit_hash)
    -- 1. Obtener la ruta del archivo activo actual en Neovim
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file == "" then
        vim.notify("No hay un archivo activo guardado en disco.", vim.log.levels.WARN)
        return
    end

    local local_path = vim.fn.fnamemodify(current_file, ":h")

    -- 2. Encontrar la raíz del repositorio Git con rev-parse
    local handle = io.popen(string.format("git -C %s rev-parse --show-toplevel", vim.fn.shellescape(local_path)))
    if not handle then return end
    local file_dir = handle:read("*a"):gsub("%s+", "")
    handle:close()

    if file_dir == "" then
        vim.notify("El archivo no pertenece a un repositorio Git.", vim.log.levels.WARN)
        return
    end

    -- 3. Calcular la ruta relativa del archivo respecto a la raíz del repositorio
    local rel_handle = io.popen(string.format("git -C %s ls-files --full-name %s", vim.fn.shellescape(file_dir), vim.fn.shellescape(current_file)))
    if not rel_handle then return end
    local rel_path = rel_handle:read("*a"):gsub("%s+", "")
    rel_handle:close()

    if rel_path == "" then
        vim.notify("El archivo no pertenece o no está trackeado en Git.", vim.log.levels.WARN)
        return
    end

    -- 4. Ejecutar el checkout del archivo para pisarlo con la versión del commit seleccionado
    -- (Nota: también puedes usar 'git restore' que es el comando moderno de git)
    local cmd = string.format("git -C %s checkout %s -- %s", vim.fn.shellescape(file_dir), vim.fn.shellescape(commit_hash), vim.fn.shellescape(rel_path))
    local success, _, stderr = os.execute(cmd)

    if success then
        vim.notify("Archivo actual actualizado con éxito desde el commit.", vim.log.levels.INFO)
        -- Opcional: Recargar el buffer actual en Neovim para que cargue los cambios en caliente
        vim.cmd("checktime")
    else
        vim.notify("Error de Git al actualizar el archivo.", vim.log.levels.ERROR)
    end
end
local function git_commit_all(commit_message)
    local cwd = path_git_work
    -- Limpiamos el mensaje del commit
    commit_message = vim.trim(commit_message)
    local msg = commit_message
    if msg == "" then
        vim.notify("El mensaje del commit no puede estar vacío", vim.log.levels.WARN)
        return false
    end

    -- Nota: -am hace git add de archivos trackeados y el commit de una vez
    local success, obj = pcall(function()
        return vim.system({ "git", "commit", "-am", msg }, {
            cwd = cwd,
            text = true,
        }):wait()
    end)

    -- Equivalente al bloque catch
    if not success or obj.code ~= 0 then
        local err_msg = (obj and obj.stderr and obj.stderr ~= "") and obj.stderr or "Error desconocido al hacer el commit"
        vim.notify("Error: " .. vim.trim(err_msg), vim.log.levels.WARN)
        return false
    end

    -- Equivalente al bloque try con éxito
    vim.notify("Commit creado con éxito: " .. msg, vim.log.levels.INFO)
    return true
end
local function openCommitFile(commit_hash)
    -- 1. Obtener la ruta del archivo actual en Neovim
    local current_file = vim.api.nvim_buf_get_name(0)
    if current_file == "" then
        vim.notify("No hay un archivo activo guardado en disco.", vim.log.levels.WARN)
        return
    end

    local local_path = vim.fn.fnamemodify(current_file, ":h")

    -- 2. Encontrar la raíz del repositorio Git con rev-parse
    local handle = io.popen(string.format("git -C %s rev-parse --show-toplevel", vim.fn.shellescape(local_path)))
    if not handle then return end
    local file_dir = handle:read("*a"):gsub("%s+", "")
    handle:close()

    if file_dir == "" then
        vim.notify("El archivo no pertenece a un repositorio Git.", vim.log.levels.WARN)
        return
    end

    -- 3. Calcular la ruta relativa del archivo respecto a la raíz del repo
    -- Neovim tiene una función interna para rutas relativas, o podemos usar un comando de shell seguro
    local rel_handle = io.popen(string.format("git -C %s ls-files --full-name %s", vim.fn.shellescape(file_dir), vim.fn.shellescape(current_file)))
    if not rel_handle then return end
    local rel_path = rel_handle:read("*a"):gsub("%s+", "")
    rel_handle:close()

    if rel_path == "" then
        vim.notify("El archivo no pertenece o no está trackeado en Git.", vim.log.levels.WARN)
        return
    end

    -- 4. Obtener el contenido del archivo en ese commit específico (equivalente a git show commit:path)
    local content_handle = io.popen(string.format("git -C %s show %s:%s", vim.fn.shellescape(file_dir), vim.fn.shellescape(commit_hash), vim.fn.shellescape(rel_path)))
    if not content_handle then return end
    local content = content_handle:read("*a")
    content_handle:close()

    if content == "" then
        vim.notify(string.format("El archivo no existía o está vacío en el commit %s.", commit_hash), vim.log.levels.WARN)
        return
    end

    -- 5. Crear un buffer nuevo (sin nombre/scratch) y volcarle el contenido
    -- Esto simula la pestaña virtual de VS Code
    vim.cmd("enew")
    local bufnr = vim.api.nvim_get_current_buf()

    -- Opcional: configurar el buffer como de solo lectura y sin nombre en disco
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].swapfile = false
    
    -- Copiar el tipo de archivo (lenguaje) actual para conservar el resaltado de sintaxis
    local current_ft = vim.bo[0].filetype
    vim.bo[bufnr].filetype = current_ft

    -- Escribir las líneas de contenido en el buffer
    local lines = vim.split(content, "\n", { plain = true })
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    -- Poner el buffer en modo de solo lectura para evitar ediciones accidentales
    vim.bo[bufnr].modifiable = false

    -- Cambiar el nombre del buffer para que se vea claro en la pestaña/barra de estado
    local display_name = string.format("[%s] %s", commit_hash:sub(7), vim.fn.fnamemodify(current_file, ":t"))
    vim.api.nvim_buf_set_name(bufnr, display_name)
end
local function viewfilescommit(hash)
    local cwd = path_git_work
    local file_handle = io.popen(string.format("git -C %s show --name-only --pretty='' %s", vim.fn.shellescape(cwd), hash))
    if not file_handle then return end
    local file_result = file_handle:read("*a")
    file_handle:close()

    local file_items = {}
    for file in file_result:gmatch("[^\r\n]+") do
      if file ~= "" then
        table.insert(file_items, file)
      end
    end

    MiniPick.start({
      source = {
        name = "Archivos en: " .. hash, -- Corregido: usamos directamente 'hash'
        items = file_items,
        choose = function(chosen_file)
          if chosen_file then
            -- Abrimos el archivo tomando en cuenta la ruta absoluta o relativa correcta
            vim.cmd("edit " .. vim.fn.fnameescape(cwd .. "/" .. chosen_file))
          end
        end,
      },
    })
end
local function view_commits()
  -- Obtenemos la ruta actual de trabajo en Neovim
  local cwd = path_git_work
  
  -- Ejecutamos git log apuntando explícitamente a esa ruta
  local handle = io.popen(string.format("git -C %s log --decorate --oneline", vim.fn.shellescape(cwd)))
  if not handle then return end
  local result = handle:read("*a")
  handle:close()

  local items = {}
  for line in result:gmatch("[^\r\n]+") do
    local hash, message = line:match("^(%S+)%s+(.*)$")
    if hash then
      table.insert(items, {
        text = line,
        hash = hash,
        message = message,
      })
    end
  end
  --opciones del commit seleccionado
  MiniPick.start({
    source = {
      name = "Commits de Git (" .. vim.fn.fnamemodify(cwd, ":t") .. ")",
      items = items,
      choose = function(item)
        if not item then return end
        local hashi = item.hash
        local file_items = {
          { text = "files commit", action = "filesOnCommit" },
          { text = "view commit buffer", action = "openbuffer" },
          { text = "merge current file", action = "mergeCurrent" },
          { text = "merge all commit", action = "mergeall" },
        }
        MiniPick.start({
          
          source = {
            name = "Archivos en: " .. item.hash,
            items = file_items,
            choose = function(item)

            if not item then return end

            if item.action == "filesOnCommit" then
                vim.schedule(function()
                  viewfilescommit(hashi)
                end)
            elseif item.action == "openbuffer" then
                vim.schedule(function()
                   openCommitFile(hashi)
                end)
            elseif item.action == "mergeCurrent" then
                vim.schedule(function()
                   copyCommitCurrentFile(hashi)
                end)
            elseif item.action == "mergeall" then
                vim.schedule(function()
                   copyCommitAllFiles(hashi)
                end)
            end
            end,
          },
        })
      end,
    },
  })
end
local function create_and_switch_branch(branch_name)
    local cwd = path_git_work 
    if not branch_name or branch_name == "" then
        vim.notify("El nombre de la rama no puede estar vacío", vim.log.levels.WARN)
        return false
    end

    -- Ejecutamos el comando de git de forma sincrónica
    local success, obj = pcall(function()
        return vim.system({ "git", "checkout", "--orphan", branch_name }, {
            cwd = cwd,
            text = true,
        }):wait()
    end)

    -- Verificamos si hubo un error en la ejecución o el comando falló
    if not success or obj.code ~= 0 then
        local err_msg = (obj and obj.stderr and obj.stderr ~= "") and obj.stderr or "Error desconocido al crear la rama"
        vim.notify("Error: " .. vim.trim(err_msg), vim.log.levels.WARN)
        return false
    end
    success, obj = pcall(function()
        return vim.system({ "git", "reset"}, {
            cwd = cwd,
            text = true,
        }):wait()
    end)
    if not success or obj.code ~= 0 then
        local err_msg = (obj and obj.stderr and obj.stderr ~= "") and obj.stderr or "Error desconocido al crear la rama"
        vim.notify("Error: " .. vim.trim(err_msg), vim.log.levels.WARN)
        return false
    end

    -- Éxito (equivalente al try)
    vim.notify("Rama creada y cambiada con éxito: " .. branch_name, vim.log.levels.INFO)
    return true
end

local function set_name_input(context)
    local line = vim.api.nvim_get_current_line()
    local input = "" 
    if context  == "branch" then
      input = line:gsub("^nameBranch:%s*", "")
    elseif context == "commit" then
      input = line:gsub("^nameCommit:%s*", "")
    end 
    if input == "" then return end
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
    if context  == "branch" then
      create_and_switch_branch(input)
    elseif context == "commit" then
      git_commit_all(input)
    end
end
local function input_name_git_mode(context)
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
    
    if context == "branch" then
      vim.fn.prompt_setprompt(input_buf, "nameBranch: ")
    elseif context == "commit" then
      vim.fn.prompt_setprompt(input_buf, "nameCommit: ")
    end
    -- Space → buscar y cerrar
    vim.keymap.set("i", "<Space>", function()
        if context == "branch" then
          set_name_input(context)
        elseif context == "commit" then
          set_name_input(context)
        end
    end, { buffer = input_buf })
    vim.cmd("startinsert")
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
        result = vim.trim(result)   
        path_git_work = result
    else
        vim.notify("El directorio no es un repositorio de Git", vim.log.levels.WARN)
        return nil
    end
end

local function pick_accion_git()
    local acciones = {
      { text = "new commit", action = "newcommit" },
      { text = "new branch", action = "newbranch" },
      { text = "view commits", action = "viewCommit" },
      { text = "view branch", action = "viewbranch" },
      { text = "gitHub", action = "pushgitHub" },
    }
      MiniPick.start({
        source = {
          name = "Acciones Git",
          items = acciones,
          -- Función que se ejecuta al presionar Enter sobre una opción
          choose = function(item)
            if not item then return end

            if item.action == "newcommit" then
                vim.schedule(function()
                  input_name_git_mode("commit")
                end)
            elseif item.action == "newbranch" then
                vim.schedule(function()
                   input_name_git_mode("branch")
                end)
            elseif item.action == "viewbranch" then
                vim.schedule(function()
                   pickGitBranches()
                end)
            elseif item.action == "pushgitHub" then
                vim.schedule(function()
                   github_check()
                end)
            elseif item.action == "viewCommit" then
                vim.schedule(function()
                   view_commits()
                end)
            end
            end,
        },
      })
end
local function init_git_repo(local_path)
    local cwd = local_path
    local obj = vim.system({ "git", "init" }, {
        cwd = cwd,
        text = true, -- Decodifica la salida automáticamente a string
    }):wait()
    if obj.code == 0 then
        vim.notify("Repositorio Git inicializado con éxito.", vim.log.levels.INFO)
        return true
    else
        local err_msg = (obj.stderr and obj.stderr ~= "") and obj.stderr or obj.stdout
        vim.notify("Error al inicializar Git: " .. vim.trim(err_msg), vim.log.levels.WARN)
        return false
    end
end
local function git_tool(local_path)
    local cwd = local_path 
    local obj = vim.system({ "git", "rev-parse", "--show-toplevel" }, {
        cwd = cwd,
        text = true, -- Decodifica la salida automáticamente a string
    }):wait() -- .wait() hace que sea sincrónico (espera el resultado como tu ejemplo en JS)
    if obj.code == 0 and obj.stdout then
       get_git_root(cwd)
       pick_accion_git() 
    else
        vim.ui.select({ "Sí", "No" }, { prompt = "¿desea iniciar git ?" }, function(choice)
          if choice == "Sí" then
              init_git_repo(cwd)
            else
              print("no git work")
            end
        end)
    end
end
vim.keymap.set("v", "t", function()
    local curdir = vim.fn.expand("%:p:h")
    git_tool(curdir)
end, opts)

