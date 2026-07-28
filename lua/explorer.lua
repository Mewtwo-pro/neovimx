

local original_buf = nil
local original_win = nil
local input_buf = nil
local input_win = nil
local path_netrw = nil
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
    vim.keymap.set("n", "b", function()
      -- Obtener la ruta del archivo o directorio actual bajo el cursor en netrw
-- Obtener la ruta del archivo o directorio actual bajo el cursor en netrw de forma segura
local cfile = vim.fn.expand("<cfile>")
local curdir = vim.b.netrw_curdir or vim.fn.expand("%:p:h")
local target_path = curdir .. "/" .. cfile
      -- Definir las acciones disponibles en mini.pick
local acciones = {
  { text = "Crear nuevo archivo aquí", action = "create_file" },
  { text = "Eliminar: " .. cfile, action = "delete", path = target_path },
  { text = "set play compiler", action = "playcmd" },
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
            
            elseif item.action == "playcmd" then
                vim.schedule(function()
                   seleccionar_task(curdir)
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
    
vim.api.nvim_create_autocmd("FileType", {
    pattern = "netrw",
    callback = function(ev)
        vim.keymap.set("n", "x", seleccionar_task, {
            buffer = ev.buf,
            silent = true,
        })
    end,
})
