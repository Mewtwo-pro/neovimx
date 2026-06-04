
local original_buf = nil
local original_win = nil
local input_buf = nil
local input_win = nil

function _G.input_flash()
    original_buf = vim.api.nvim_get_current_buf()
    original_win = vim.api.nvim_get_current_win()

    input_buf = vim.api.nvim_create_buf(false, true)


    local width, height = 30, 1
    local row = vim.o.lines - height - 2  -- casi abajo del todo
    local col = 1                         -- parte izquierda
    
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
    vim.fn.prompt_setprompt(input_buf, "Buscar: ")
    -- Space → buscar y cerrar
    vim.keymap.set("i", "<Space>", function()
        _G.flash_machine()
    end, { buffer = input_buf })
    vim.cmd("startinsert")
end
_G.caracter_reemplazar = "c"
function _G.flash_machine()
    local line = vim.api.nvim_get_current_line()
    local input = line:gsub("^Buscar:%s*", "")
    if input == "" then return end
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
    _G.caracter_reemplazar = input 
  require("flash").jump({
    pattern = _G.caracter_reemplazar
  })

  vim.schedule(function()
   vim.cmd("normal! l")
  end)
  saltar_prefijo()
end

function _G.flash_local()
  require("flash").jump({
    pattern = _G.caracter_reemplazar
  })
  saltar_prefijo()
end
    
function _G.saltar_prefijo()
  prefijo = _G.caracter_reemplazar 
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  -- Buscar el prefijo en la palabra bajo el cursor
  local s, e = string.find(line, prefijo, col + 1) -- busca desde la posición actual
  if not s then
    -- Si no lo encuentra desde el cursor, busca en toda la línea
    s, e = string.find(line, prefijo)
  end

  if s and e then
    -- Mueve el cursor al final del prefijo
    vim.api.nvim_win_set_cursor(0, {row, e})
  else
    print("Prefijo no encontrado en la palabra")
  end
end

-- Para "primavera" -> va a la 'a' de prima
vim.api.nvim_set_keymap("n", "v", "<Esc>:lua _G.flash_local()<CR>", { noremap = true, silent = true })
vim.keymap.set({'n','x','o'}, 't', _G.input_flash, { desc = "Flash Jump + derecha" })
