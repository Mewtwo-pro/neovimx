local ns = vim.api.nvim_create_namespace("range_jump")

function _G.RangeJumpOrSelect()

    local first = vim.fn.line("w0")
    local last  = vim.fn.line("w$")

    local labels = {}
    for c in ("abcdefghijklmnopqrstuvwxyzVWXYZ"):gmatch(".") do
        table.insert(labels, c)
    end

    local map = {}

    -- limpiar marcas anteriores
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    local i = 1

    for line = first, last do

        if i > #labels then
            break
        end

        if vim.fn.foldclosed(line) == -1 then

            local label = labels[i]

            vim.api.nvim_buf_set_extmark(
                0,
                ns,
                line - 1,
                0,
                {
                    virt_text = { { label, "Search" } },
                    virt_text_pos = "overlay",
                }
            )

            map[label] = line
            i = i + 1
        end
    end

    vim.cmd("redraw")
    vim.api.nvim_echo(
        {{"1 letra = saltar | 2 letras = seleccionar rango", "Normal"}},
        false,
        {}
    )

    -- primera tecla
    local key1 = vim.fn.nr2char(vim.fn.getchar())

    if not map[key1] then
        vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
        return
    end

    local start_line = map[key1]

    vim.cmd("redraw")
    vim.api.nvim_echo(
        {{"segunda letra para rango (ESC cancela)", "Normal"}},
        false,
        {}
    )

    local c = vim.fn.getchar()

    -- ESC => salto
    if c == 27 then
        vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
        vim.api.nvim_win_set_cursor(0, {start_line, 0})
        return
    end

    local key2 = vim.fn.nr2char(c)

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    -- segunda tecla inválida => salto
    if not map[key2] then
        vim.api.nvim_win_set_cursor(0, {start_line, 0})
        return
    end

    local end_line = map[key2]

    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end

    -- selección visual por líneas
    vim.api.nvim_win_set_cursor(0, {start_line, 0})
    vim.cmd("normal! V")
    vim.api.nvim_win_set_cursor(0, {end_line, 0})
end

vim.keymap.set("n", "f", RangeJumpOrSelect)
