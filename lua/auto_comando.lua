    
vim.api.nvim_create_user_command(
    'Gitnet',
    function()
        _G.input_git_net()
    end,
    {}
)    
vim.api.nvim_create_user_command(
    'Terminalocal',
    function ()
        -- 1. Obtener la ruta del archivo actual (solo la carpeta)
        local path = vim.fn.expand('%:p:h')
        
        -- 2. Abrir una nueva pestaña
        vim.cmd('tabnew')
        
        -- 3. Abrir la terminal
        vim.cmd('term')
        
        -- 4. Esperar un breve instante a que la terminal cargue y enviar el comando cd
        -- Usamos vim.api.nvim_chan_send para "escribir" en la terminal de Neovim
        local chan_id = vim.b.terminal_job_id
        if chan_id then
            -- \n actúa como el "Enter" en la terminal
            vim.api.nvim_chan_send(chan_id, "cd " .. path .. "\n")
        end
    end,
    {}
)
        

local mis_comandos = { "Terminalocal","CpPath","Taskselect","SelectAll", "Gitnet"}
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

--vim.keymap.set('n', '<CR><Space>', ejecutar_comando_con_input, { desc = "Ejecutar comando con autocompletado" })
    

-- modal 
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
    
        

   
local opts = { noremap = true, silent = true }

vim.keymap.set("n", "<CR><Space>", function()
  local cwd = vim.fn.expand("%:p:h")

  local function git(cmd)
    return vim.fn.systemlist("git -C " .. vim.fn.shellescape(cwd) .. " " .. cmd)
  end

  local acciones = {
    { text = "Status", action = "status" },
    { text = "Agregar buffer (git add)", action = "add_buffer" },
    { text = "Commit", action = "commit" },
    { text = "Ver commits", action = "log" },
    { text = "Ver ramas", action = "branches" },
    { text = "Nueva rama", action = "branch" },
    { text = "init repositorio", action = "init" },
    { text = "auto github", action = "autopush" },
  }

  MiniPick.start({
    source = {
      name = "Git",
      items = acciones,

      format_item = function(item)
        return item.text
      end,

      choose = function(item)
        if not item then
          return
        end

        if item.action == "status" then
          local out = git("status --short --branch")
          vim.cmd("new")
          vim.bo.buftype = "nofile"
          vim.bo.bufhidden = "wipe"
          vim.bo.swapfile = false
          vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
        elseif item.action == "init" then
          local out = git("init")
          vim.cmd("new")
          vim.bo.buftype = "nofile"
          vim.bo.bufhidden = "wipe"
          vim.bo.swapfile = false
          vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
        elseif item.action == "autopush" then
            _G.input_git_net(cwd)
        elseif item.action == "commit" then
          vim.ui.input({ prompt = "Mensaje del commit: " }, function(msg)
            if not msg or msg == "" then
              return
            end

            git("add .")
            local out = git("commit -m " .. vim.fn.shellescape(msg))

            vim.cmd("new")
            vim.bo.buftype = "nofile"
            vim.bo.bufhidden = "wipe"
            vim.bo.swapfile = false
            vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
          end)
        elseif item.action == "add_buffer" then
          local file = vim.fn.expand("%:p")
          local out = git("add " .. vim.fn.shellescape(file))

          vim.notify(
            "Archivo agregado al stage:\n" .. vim.fn.fnamemodify(file, ":t"),
            vim.log.levels.INFO
          )

    
        elseif item.action == "branches" then
          local ramas = git("branch")

          MiniPick.start({
            source = {
              name = "Branches",
              items = ramas,

              format_item = function(item)
                return item
              end,

              choose = function(branch)
                if not branch then
                  return
                end

                branch = branch:gsub("^%*", ""):gsub("^%s+", "")

                local out = git("switch " .. vim.fn.shellescape(branch))

                vim.notify(table.concat(out, "\n"), vim.log.levels.INFO)
              end,
            },
          })
elseif item.action == "log" then
  local commits = git("log --oneline --decorate")

  MiniPick.start({
    source = {
      name = "Commits",
      items = commits,

      choose = function(commit)
        if not commit then
          return
        end

        local hash = commit:match("^(%S+)")
        local files = git("show --name-only --pretty='' " .. hash)

        vim.cmd("new")
        vim.bo.buftype = "nofile"
        vim.bo.bufhidden = "wipe"
        vim.bo.swapfile = false
        vim.api.nvim_buf_set_lines(0, 0, -1, false, files)
      end,
    },
  })

        elseif item.action == "branch" then
          vim.ui.input({ prompt = "Nueva rama: " }, function(name)
            if not name or name == "" then
              return
            end

            local out = git("checkout -b " .. vim.fn.shellescape(name))

            vim.cmd("new")
            vim.bo.buftype = "nofile"
            vim.bo.bufhidden = "wipe"
            vim.bo.swapfile = false
            vim.api.nvim_buf_set_lines(0, 0, -1, false, out)
          end)
        end
      end,
    },
  })
end, opts)
