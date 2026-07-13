local builtin = require("telescope.builtin")

vim.keymap.set("v", "k", builtin.oldfiles, {
    desc = "Archivos recientes",
})
vim.keymap.set("n", "<CR>v", function()
    builtin.live_grep({
        search_dirs = {
            "/home/manuel/Documents/javaProyect/springBoot/demo/src/main/java/com/example/demo",
        },
    })
end, { desc = "Buscar texto" })
    
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

vim.keymap.set("n", "<CR><BS>", function()

    local carpeta_objetivo = "/home/manuel/Documents/javaProyect/springBoot/demo"

    local resultados = {}

    for _, file in ipairs(vim.v.oldfiles) do
        if file:find(carpeta_objetivo, 1, true) then
            table.insert(resultados, {
                value = file,                                    -- ruta completa
                display = file:sub(#carpeta_objetivo + 2),       -- ruta relativa
                ordinal = file,
            })
        end
    end

    pickers.new({}, {
        prompt_title = "Archivos recientes",

        finder = finders.new_table({
            results = resultados,

            entry_maker = function(entry)
                return {
                    value = entry.value,
                    display = entry.display,
                    ordinal = entry.ordinal,
                    path = entry.value,
                }
            end,
        }),

        sorter = conf.generic_sorter({}),

        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)

                local entry = action_state.get_selected_entry()
                vim.cmd.edit(vim.fn.fnameescape(entry.path))
            end)

            return true
        end,
    }):find()

end)
    
local function pin_picker()

    vim.cmd("normal! ma")

    local target_win = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_get_current_buf()

    local items = {}

    for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
        local comment = line:match("//%s*PIN:%s*(.+)$")
        if comment then
            table.insert(items, {
                lnum = lnum,
                display = string.format("%4d │ %s", lnum, comment),
                ordinal = comment,
            })
        end
    end

    if vim.tbl_isempty(items) then
        vim.notify("No se encontraron comentarios PIN")
        return
    end

    pickers.new({}, {
        prompt_title = "PIN",

        finder = finders.new_table({
            results = items,

            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.display,
                    ordinal = entry.ordinal,
                }
            end,
        }),

        sorter = conf.generic_sorter({}),

        attach_mappings = function(prompt_bufnr)

            actions.select_default:replace(function()

                actions.close(prompt_bufnr)

                local entry = action_state.get_selected_entry()

                vim.api.nvim_set_current_win(target_win)
                vim.api.nvim_win_set_cursor(target_win, {
                    entry.value.lnum,
                    0,
                })

                vim.cmd("normal! zz")
            end)

            return true
        end,

    }):find()
end

vim.keymap.set("n", "<CR>j", pin_picker, { desc = "PIN Picker" })
