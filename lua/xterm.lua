local input_buf = nil 
local input_win = nil
local term_buf = nil 
local term_win = nil 
local term_job = nil

-- ========================
-- Abrir terminal flotante (Pantalla Completa / Maximizada)
-- ========================
local function open_terminal()
  term_buf = vim.api.nvim_create_buf(false, true)

  -- Calculamos el tamaño para ocupar toda la pantalla restando un pequeño margen
  local width = vim.o.columns - 4
  local height = vim.o.lines - 6

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

local function save_cmd()
  vim.ui.input({ prompt = "Escribe tu mensaje: " }, function(input)
    if input and input ~= "" then
      -- Copiar al portapapeles del sistema (+) y a la selección (*)
      vim.fn.setreg("+", input)
    else
      vim.notify("Operación cancelada o mensaje vacío", vim.log.levels.WARN)
    end
  end)
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
    -- Envía el texto que escribiste en el input directamente a la terminal de arriba
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

  -- El input inferior también se alinea al ancho de la pantalla
  local input_width = vim.o.columns - 4

  input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = input_width,
    height = 1,
    row = vim.o.lines - 4,
    col = 2,
    style = "minimal",
    border = "rounded",
  })

  vim.bo[input_buf].buftype = "prompt"
  vim.fn.prompt_setprompt(input_buf, "Terminal > ")

  -- Callback que se ejecuta al presionar Enter en el prompt
  vim.fn.prompt_setcallback(input_buf, function(text)
    ejecutar_comando_libre(text)
    -- Limpia y vuelve a activar el prompt para seguir escribiendo más comandos
    vim.fn.feedkeys("i", "n")
  end)

  -- Tecla para salir con Escape o cerrando la ventana
  vim.keymap.set("n", "<ESC>", function()
    close_inputx()
  end, {buffer = input_buf})
  
  vim.keymap.set("i", "<ESC>", function()
    close_inputx()
  end, {buffer = input_buf})

  vim.keymap.set("i", "<f5>", function()
--    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
    vim.cmd('normal! hviw"+y')
    local buscFile = "~/.config/nvim/lua/buscardir.sh"
    ejecutar_comando_libre(buscFile)
    vim.cmd('normal! viwd')
    vim.cmd('startinsert')
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(" ", true, false, true), "n", true) 
  end, {buffer = input_buf})
end
-- Mapeo para abrirlo rápidamente (puedes cambiarlo a tu gusto)
vim.keymap.set("n", "<CR>t", function()
  if term_win == nil then
    input_run_compile()
  else
    close_inputx()
  end
end, { silent = true })
 

