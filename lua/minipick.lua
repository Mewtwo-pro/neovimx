
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

local function go_reference(item)
    --vim.cmd.edit(vim.fn.fnameescape(item.path)) 
    vim.api.nvim_win_set_cursor(0, { 
       item.lnum, math.max(item.col - 1, 0) 
    }) 
    vim.cmd('normal! zz')
    print(item.lnum)
end
vim.keymap.set('n', 'v', function()
  vim.lsp.buf.references(nil, {
    on_list = function(options)
      local items = {}

      for _, item in ipairs(options.items) do
        local filename = item.filename

        if not filename and item.bufnr and item.bufnr > 0 then
          filename = vim.api.nvim_buf_get_name(item.bufnr)
        end

        if filename and filename ~= "" then
          -- Quitar espacios y saltos de línea
          filename = vim.trim(filename)

          local lnum = item.lnum or 1
          local col = item.col or 1
            table.insert(items, {
              text = string.format(
                "%s    %s:%d:%d",
                vim.trim(item.text or ""),
                vim.fn.fnamemodify(filename, ":."),
                lnum,
                col
              ),
              path = filename,
              lnum = lnum,
              col = col,
            })
        end
      end

      MiniPick.start({
        source = {
          name = 'LSP References',
          items = items,

          choose = function(item)
            if not item then
              return
            end
            --
            vim.schedule(function()
               go_reference(item)
            end)
          end,
        },
      })
    end,
  })
end, { desc = 'Ver referencias con MiniPick' })
local function go_pinline(item)    
        vim.api.nvim_win_set_cursor(0, { item.lnum, 0 })
        vim.cmd("normal! zz")
end
local function pick_code_pins()
  -- 1. Obtener todas las líneas del buffer actual
  local current_buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)

  -- 2. Filtrar las líneas que contengan el formato //Pin:
  local items = {}
  for lnum, line in ipairs(lines) do
    -- Busca líneas que tengan '//Pin:' (con espacios opcionales antes o después)
    local pin_text = line:match("^%s*//%s*Pin:%s*(.*)$")
    if pin_text then
      table.insert(items, {
        -- Texto que se mostrará en la lista de mini.pick
        text = string.format("Línea %d: %s", lnum, pin_text),
        -- Datos útiles para cuando el usuario seleccione la opción
        lnum = lnum,
        bufnr = current_buf,
      })
    end
  end

  -- Validar si se encontraron pines
  if #items == 0 then
    vim.notify("No se encontraron comentarios con el formato //Pin:", vim.log.levels.INFO)
    return
  end

  -- 3. Configurar y abrir mini.pick
  MiniPick.start({
    source = {
      name = "Code Pins",
      items = items,
      -- Función que se ejecuta al presionar Enter sobre un elemento
      choose = function(item)
        vim.schedule(function()
          go_pinline(item)
        end)
      end,
    },
  })
end

-- Opcional: Asignarle un atajo de teclado (ej. <leader>dp)
vim.keymap.set("n", "bi", pick_code_pins, { desc = "Buscar comentarios //Pin:" })
