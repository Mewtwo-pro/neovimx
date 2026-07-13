local ns = vim.api.nvim_create_namespace("range_jump")

local function read_label(map)              
    local input = ""

    while true do
        local c = vim.fn.getchar()

        if c == 27 then
            return "__ESC__"
        end

        input = input .. vim.fn.nr2char(c)

        if map[input] then
            return input
        end

        local possible = false

        for k, _ in pairs(map) do
            if k:sub(1, #input) == input then
                possible = true
                break
            end
        end

        if not possible then
            return nil
        end
    end
end

function _G.RangeJumpOrSelect()         

    local first = vim.fn.line("w0")
    local last = vim.fn.line("w$")

    local labels = {}

    -- a..z
    for c in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
        table.insert(labels, c)
    end

    -- -a..-g
    for c in ("abcdefg"):gmatch(".") do
        table.insert(labels, ";" .. c)
    end

    local map = {}

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    local i = 1

    for line = first, last do

        if i > #labels then
            break
        end

        if vim.fn.foldclosed(line) == -1 then

            local label = labels[i]

            vim.api.nvim_buf_set_extmark(0, ns, line - 1, 0, {
                virt_text = { { label, "Search" } },
                virt_text_pos = "inline",
            })
            map[label] = line
            i = i + 1
        end
    end

    vim.cmd("redraw")

    vim.api.nvim_echo(
        { { "saltar", "Normal" } },
        false,
        {}
    )

    local key1 = read_label(map)

    if not key1 or key1 == "__ESC__" then
        vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
        return
    end

    local start_line = map[key1]

    vim.cmd("redraw")

    vim.api.nvim_echo(
        { { "segunda etiqueta (ESC para solo saltar)", "Normal" } },
        false,
        {}
    )

    local key2 = read_label(map)

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    if key2 == "__ESC__" then
        vim.api.nvim_win_set_cursor(0, { start_line, 0 })
        return
    end

    if not key2 then
        vim.api.nvim_win_set_cursor(0, { start_line, 0 })
        return
    end

    local end_line = map[key2]

    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    vim.api.nvim_win_set_cursor(0, { start_line, 0 })
    vim.cmd("normal! V")
    vim.api.nvim_win_set_cursor(0, { end_line, 0 })
end

vim.api.nvim_set_keymap("n", "f", "0ma:lua _G.RangeJumpOrSelect()<CR>" ,{ noremap = true, silent= true})
vim.api.nvim_set_keymap("v", "f", "<Esc>0ma:lua _G.RangeJumpOrSelect()<CR>" ,{ noremap = true, silent= true})
    
local original_buf = nil
local original_win = nil
local input_buf = nil
local input_win = nil

function _G.input_range_chars()
    original_buf = vim.api.nvim_get_current_buf()
    original_win = vim.api.nvim_get_current_win()

    input_buf = vim.api.nvim_create_buf(false, true)

    local width, height = 30, 1
    local row, col = 0, vim.o.columns - width

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
        _G.select_between_chars()
    end, { buffer = input_buf })
    vim.cmd("startinsert")
end
 
        
function _G.select_between_chars()
    
    local line = vim.api.nvim_get_current_line()
    local input = line:gsub("^Buscar:%s*", "")
    if input == "" then return end
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
    
    if not input or input == "" then
        return
    end

    local chars = {}
    for c in input:gmatch("%S") do
        table.insert(chars, c)
    end

    if #chars < 2 then
        vim.notify("Debe ingresar dos letras")
        return
    end

    local char_back = chars[1]
    local char_forward = chars[2]

    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local text = table.concat(lines, "\n")

    -- posición absoluta del cursor
    local cursor_pos = 0
    for i = 1, row - 1 do
        cursor_pos = cursor_pos + #lines[i] + 1
    end
    cursor_pos = cursor_pos + col

    -- buscar hacia atrás
    local start_pos
    local i = cursor_pos

    while i > 0 do
        if text:sub(i, i) == char_back then
            start_pos = i + 1
            break
        end
        i = i - 1
    end

    if not start_pos then
        vim.notify("No se encontró '" .. char_back .. "' hacia atrás")
        return
    end

    -- buscar hacia adelante
    local end_pos
    i = cursor_pos + 1

    while i <= #text do
        if text:sub(i, i) == char_forward then
            end_pos = i - 1
            break
        end
        i = i + 1
    end

    if not end_pos then
        vim.notify("No se encontró '" .. char_forward .. "' hacia adelante")
        return
    end

    -- convertir posiciones absolutas a (fila,columna)
    local function pos_to_rc(pos)
        local p = 0

        for r, line in ipairs(lines) do
            local len = #line + 1

            if pos <= p + len then
                return r - 1, pos - p - 1
            end

            p = p + len
        end

        return #lines - 1, #lines[#lines]
    end

    local sr, sc = pos_to_rc(start_pos)
    local er, ec = pos_to_rc(end_pos + 1)

    vim.fn.setpos("'<", {0, sr + 1, sc + 1, 0})
    vim.fn.setpos("'>", {0, er + 1, ec + 1, 0})

    vim.cmd("normal! gv")
end
--mayuscula
vim.api.nvim_set_keymap("v", "e", "<Esc>:lua _G.input_range_chars()<CR>" ,{ noremap = true, silent= true})
vim.api.nvim_set_keymap("v", "<CR>f", "U" ,{ noremap = true, silent= true})
    
vim.keymap.set("n", "d", "mq", { noremap = true })
vim.keymap.set("n", "c", "V`q", { noremap = true })
vim.keymap.set("v", "c", "`q", { noremap = true })
vim.keymap.set("n", "k", "`q", { noremap = true })
function _G.input_my_flash()
    original_buf = vim.api.nvim_get_current_buf()
    original_win = vim.api.nvim_get_current_win()

    input_buf = vim.api.nvim_create_buf(false, true)

    local width, height = 30, 1
    local row, col = 0, vim.o.columns - width

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
        _G.VisibleCharJump()
    end, { buffer = input_buf })
    vim.cmd("startinsert")
end
local ns = vim.api.nvim_create_namespace("visible_jump")

local labels = {}
for c in ("abcdefghijklmnopqrstuvwxy"):gmatch(".") do
    table.insert(labels, c)
end

local function clear_marks()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

local function draw_matches(groups)
    clear_marks()

    for label, matches in pairs(groups) do
        for _, m in ipairs(matches) do
            vim.api.nvim_buf_set_extmark(
                0,
                ns,
                m.row,
                m.col,
                {
                    virt_text = { { label, "Search" } },

                    -- Cambia a "overlay" si prefieres
                    -- que la letra se dibuje encima.
                    virt_text_pos = "inline",

                    priority = 9999,
                }
            )
        end
    end

    vim.cmd("redraw")
end

local function build_groups(matches)
    local groups = {}
    local overflow = {}

    for i, match in ipairs(matches) do
        if i <= #labels then
            groups[labels[i]] = { match }
        else
            table.insert(overflow, match)
        end
    end

    if #overflow > 0 then
        groups["z"] = overflow
    end

    return groups
end

local function jump_recursive(matches)

    if #matches == 0 then
        clear_marks()
        return
    end

    if #matches == 1 then
        local m = matches[1]

        clear_marks()
 
        vim.api.nvim_win_set_cursor(
            0,
            { m.row + 1, m.col + 2 }
        )
        return
    end

    local groups = build_groups(matches)

    draw_matches(groups)

    local key = vim.fn.getcharstr()

    if key == "\027" then
        clear_marks()
        return
    end

    local next_matches = groups[key]

    if not next_matches then
        clear_marks()
        return
    end

    jump_recursive(next_matches)
end
local current_char = "m"
    
function _G.CurrentCharJump()
    local input = current_char  
    if not input or input == "" then
        return
    end

        local target = input:sub(1, 1)

        local first = vim.fn.line("w0")
        local last = vim.fn.line("w$")

        local matches = {}

        local lnum = first

        while lnum <= last do

            -- ¿inicio de fold cerrado?
            local fold_start = vim.fn.foldclosed(lnum)

            if fold_start ~= -1 then

                -- saltar todo el fold
                lnum = vim.fn.foldclosedend(lnum) + 1

            else

                local text = vim.fn.getline(lnum)

                local start = 1

                while true do

                    local s = text:find(
                        target,
                        start,
                        true
                    )

                    if not s then
                        break
                    end

                    table.insert(matches, {
                        row = lnum - 1,
                        col = s - 1,
                    })

                    start = s + 1
                end

                lnum = lnum + 1
            end
        end

        if #matches == 0 then
            vim.notify(
                "No se encontraron coincidencias",
                vim.log.levels.INFO
            )
            return
        end

        jump_recursive(matches)
end
function _G.VisibleCharJump()
    
    local line = vim.api.nvim_get_current_line()
    local input = line:gsub("^Buscar:%s*", "")
    if input == "" then return end
    vim.api.nvim_win_close(input_win, true)
    vim.api.nvim_buf_delete(input_buf, { force = true })
    current_char = input 
    if not input or input == "" then
            return
    end

        local target = input:sub(1, 1)

        local first = vim.fn.line("w0")
        local last = vim.fn.line("w$")

        local matches = {}

        local lnum = first

        while lnum <= last do

            -- ¿inicio de fold cerrado?
            local fold_start = vim.fn.foldclosed(lnum)

            if fold_start ~= -1 then

                -- saltar todo el fold
                lnum = vim.fn.foldclosedend(lnum) + 1

            else

                local text = vim.fn.getline(lnum)

                local start = 1

                while true do

                    local s = text:find(
                        target,
                        start,
                        true
                    )

                    if not s then
                        break
                    end

                    table.insert(matches, {
                        row = lnum - 1,
                        col = s - 1,
                    })

                    start = s + 1
                end

                lnum = lnum + 1
            end
        end

        if #matches == 0 then
            vim.notify(
                "No se encontraron coincidencias",
                vim.log.levels.INFO
            )
            return
        end

        jump_recursive(matches)
end

vim.api.nvim_set_keymap("n", "v", "mq:lua _G.CurrentCharJump()<CR>" ,{ noremap = true, silent= true})
vim.api.nvim_set_keymap("v", "t", "<Esc>mq:lua _G.input_my_flash()<CR>" ,{ noremap = true, silent= true})
vim.api.nvim_set_keymap("n", "t", "mq:lua _G.input_my_flash()<CR>" ,{ noremap = true, silent= true})
    
local ns = vim.api.nvim_create_namespace("line_word_jump")

local labels = {}
for c in ("abcdefghijklmnopqrstuvwxy"):gmatch(".") do
    table.insert(labels, c)
end

local function clear_marks()
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

local function draw_groups(groups)
    clear_marks()

    for label, words in pairs(groups) do
        for _, w in ipairs(words) do
            vim.api.nvim_buf_set_extmark(
                0,
                ns,
                w.row,
                w.col,
                {
                    virt_text = { { label, "Search" } },
                    virt_text_pos = "overlay",
                    priority = 9999,
                }
            )
        end
    end

    vim.cmd("redraw")
end

local function build_groups(items)
    local groups = {}
    local overflow = {}

    for i, item in ipairs(items) do
        if i <= #labels then
            groups[labels[i]] = { item }
        else
            table.insert(overflow, item)
        end
    end

    if #overflow > 0 then
        groups["z"] = overflow
    end

    return groups
end

local function select_word(items)

    if #items == 0 then
        clear_marks()
        return
    end

    if #items == 1 then
        local item = items[1]

        clear_marks()

        vim.api.nvim_win_set_cursor(
            0,
            { item.row + 1, item.col }
        )

        return
    end

    local groups = build_groups(items)

    draw_groups(groups)

    local key = vim.fn.getcharstr()

    if key == "\027" then
        clear_marks()
        return
    end

    if not groups[key] then
        clear_marks()
        return
    end

    select_word(groups[key])
end
    
local function is_keyword(ch)
    return vim.fn.match(ch, "\\k") ~= -1
end

local function get_word_starts(line)
    local starts = {}

    local prev_type = nil

    for col = 1, #line do

        local ch = line:sub(col, col)

        local current_type

        if ch:match("%s") then
            current_type = "space"
        elseif is_keyword(ch) then
            current_type = "keyword"
        else
            current_type = "symbol"
        end

        if current_type ~= "space" then
            if prev_type == nil or prev_type ~= current_type then
                table.insert(starts, col - 1)
            end
        end

        prev_type = current_type
    end

    return starts
end

function _G.LineWordJump()

    local row = vim.api.nvim_win_get_cursor(0)[1]
    local text = vim.fn.getline(row)

    local words = {}

    local starts = get_word_starts(text)

    for _, col in ipairs(starts) do
        table.insert(words, {
            row = row - 1,
            col = col,
        })
    end

    if #words == 0 then
        return
    end

    select_word(words)
end

vim.keymap.set(
    "n",
    "e",
    _G.LineWordJump,
    {
        noremap = true,
        silent = true,
        desc = "Jump to word in current line"
    }
)
    
local ns = vim.api.nvim_create_namespace("jump_columns")
vim.api.nvim_set_hl(0, "JumpColumnsHint", { bg = "#3c3836", fg = "#ffffff", bold = true })
function JumpColumns()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1

    local labels = {
        "a","b","c","d","e","f",
        "g","h","i","j","k","l"
    }

    -- Limpiar etiquetas anteriores
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    -- Dibujar etiquetas cada 4 columnas
    for idx, label in ipairs(labels) do
        local target_col = (idx - 1) * 4

        vim.api.nvim_buf_set_extmark(
            0,
            ns,
            row,
            0,
            {
                virt_text = {{label , "JumpColumnsHint"}},
                virt_text_win_col = target_col,
            }
        )
    end

    -- Fuerza el renderizado
    vim.cmd("redraw")

    -- Esperar una tecla
    local key = vim.fn.nr2char(vim.fn.getchar())

    -- Borrar las etiquetas
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    -- Buscar la letra seleccionada
    for idx, label in ipairs(labels) do
        if key == label then
            local target_col = (idx - 1) * 4
            
            -- --- NUEVA LÓGICA PARA CREAR LOS ESPACIOS ---
            -- Obtener el texto actual de la línea
            local current_line = vim.api.nvim_get_current_line()
            local current_len = #current_line

            -- Si la línea es más corta que la columna a la que queremos ir
            if current_len < target_col then
                -- Calcular cuántos espacios faltan
                local spaces_needed = target_col - current_len
                local padding = string.rep(" ", spaces_needed)
                
                -- Agregar los espacios al final de la línea actual
                vim.api.nvim_set_current_line(current_line .. padding)
            end

            -- Ahora que los espacios existen (o ya existían), movemos el cursor con seguridad
            vim.api.nvim_win_set_cursor(0, {row + 1, target_col})
            return
        end
    end
end

vim.keymap.set("n", "<CR>r", JumpColumns, { desc = "Jump to indentation column (creating spaces)" })
    
-- Estilo visual plomo para las sugerencias
vim.api.nvim_set_hl(0, "JumpColumnsHint", { bg = "#3c3836", fg = "#ffffff", bold = true })

-- TABLA DE ETIQUETAS COMPARTIDA
local labels = {
    "a","b","c","d","e","f",
    "g","h","i","j","k","l"
}

-- 1. FUNCIÓN ORIGINAL PARA MODO NORMAL (Mover Cursor)
function JumpColumnsNormal()
    local row = vim.api.nvim_win_get_cursor(0)[1] - 1
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    for idx, label in ipairs(labels) do
        local target_col = (idx - 1) * 4
        vim.api.nvim_buf_set_extmark(0, ns, row, 0, {
            virt_text = {{label, "JumpColumnsHint"}},
            virt_text_win_col = target_col,
        })
    end

    vim.cmd("redraw")
    local key = vim.fn.nr2char(vim.fn.getchar())
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    for idx, label in ipairs(labels) do
        if key == label then
            local target_col = (idx - 1) * 4
            local current_line = vim.api.nvim_get_current_line()
            if #current_line < target_col then
                vim.api.nvim_set_current_line(current_line .. string.rep(" ", target_col - #current_line))
            end
            vim.api.nvim_win_set_cursor(0, {row + 1, target_col})
            return
        end
    end
end

-- 2. NUEVA FUNCIÓN PARA MODO VISUAL (Mover Bloque de Texto)
    
function JumpColumnsVisual()
    -- 1. ¡CRÍTICO! Salir del modo visual para actualizar las marcas '< y '>
    -- Usamos \28\14 que equivale a <C-\><C-n> (salir a modo normal de forma segura)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "x", true)

    -- 2. Ahora sí podemos leer el rango real seleccionado
    local start_row = vim.fn.getpos("'<")[2]
    local end_row = vim.fn.getpos("'>")[2]

    if start_row == 0 or end_row == 0 then
        return
    end

    -- Asegurar que start_row sea el menor (por si seleccionaste de abajo hacia arriba)
    if start_row > end_row then
        start_row, end_row = end_row, start_row
    end

    -- Línea donde se mostrarán las etiquetas (0-based para extmarks)
    local hint_row = math.max(0, start_row - 2)

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    -- Mostrar etiquetas
    for idx, label in ipairs(labels) do
        local target_col = (idx - 1) * 4

        vim.api.nvim_buf_set_extmark(0, ns, hint_row, 0, {
            virt_text = {{label, "JumpColumnsHint"}},
            virt_text_win_col = target_col,
        })
    end

    vim.cmd("redraw")

    local key = vim.fn.nr2char(vim.fn.getchar())

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    for idx, label in ipairs(labels) do
        if key == label then
            local target_col = (idx - 1) * 4

            -- Obtener indentación actual de la primera línea
            local first_line = vim.fn.getline(start_row)
            local current_indent = # (first_line:match("^%s*") or "")

            local diff = target_col - current_indent

            if diff > 0 then
                --------------------------------------------------
                -- Agregar espacios
                --------------------------------------------------
                local spaces = string.rep(" ", diff)

                for r = start_row, end_row do
                    local line = vim.fn.getline(r)
                    if line ~= "" then
                        vim.fn.setline(r, spaces .. line)
                    end
                end

            elseif diff < 0 then
                --------------------------------------------------
                -- Quitar únicamente espacios iniciales
                --------------------------------------------------
                local remove = math.abs(diff)

                for r = start_row, end_row do
                    local line = vim.fn.getline(r)
                    local indent = # (line:match("^%s*") or "")
                    local to_remove = math.min(remove, indent)

                    vim.fn.setline(
                        r,
                        line:sub(to_remove + 1)
                    )
                end
            end

            -- Volver a seleccionar el bloque automáticamente
            vim.cmd("normal! gv")
            return
        end
    end
    
    -- Si presionas otra tecla cancelando el salto, re-seleccionamos de todos modos
    vim.cmd("normal! gv")
end
-- "x" para modo Visual (mueve el bloque de texto seleccionado)
vim.keymap.set("x", "p", JumpColumnsVisual, { desc = "Move selected block to indentation level" })   
    
local function fold_same_indent()
    local indent = vim.fn.indent(".")
    local last = vim.fn.line("$")

    for l = 1, last do
        if vim.fn.indent(l) == indent then
            vim.api.nvim_win_set_cursor(0, {l, 0})
            vim.cmd("normal! zc")
        end
    end
end

vim.keymap.set("n", "<CR>p", fold_same_indent,
    { desc = "Fold misma indentación" })
