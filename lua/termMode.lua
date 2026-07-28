-- Función auxiliar rápida para acortar la sintaxis
local function tmap(lhs, rhs)
  vim.keymap.set('t', lhs, rhs, { noremap = true, silent = true })
end
-- Opción recomendada (usando vim.keymap.set)
vim.keymap.set('t', '-', '<C-\\><C-n>vUa', { noremap = true, silent = true })
-- Mapeos en Modo Terminal ('t')
tmap('<Tab>d', '=')
tmap('<Tab>a', ':')
tmap('<Tab>s', '.')
tmap('<Tab>f', '/')
tmap('<Tab>w', ',')
tmap('<Tab>e', '$')
tmap('<Tab>r', '()<Left>')
tmap('<Tab>z', '<><Left>')
tmap('<Tab>x', '&')
tmap('<Tab>c', '""<Left>')
tmap('<Tab>i', '+')
tmap('<Tab>t', '*')
tmap('<Tab>v', '-')
tmap('<Tab>k', '_')
tmap('<Tab>q', '#')
tmap('<Tab>y', '%')
tmap('<Tab>l', "''<Left>")
tmap('<Tab>g', '{}<Left>')
tmap('<Tab>j', '``<Left>')
tmap('<Tab>p', '[]<Left>')
tmap('<Tab>o', '@')
tmap('<Tab>u', ';')
tmap('<Tab>n', '\\')
tmap('<Tab>m', '|')
tmap('<Tab>b', '!')
tmap(';', '<C-\\><C-n>')
    
local function activar_mayuscula()
    local buf = vim.api.nvim_get_current_buf()

    for letra in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
        vim.keymap.set("t", letra, function()
            -- enviar la letra en mayúscula
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, false, true),
                "n",
                false
            )

            vim.api.nvim_feedkeys(string.upper(letra), "n", false)

            vim.api.nvim_feedkeys("i", "n", false)

            -- eliminar todos los mapeos temporales
            for l in ("abcdefghijklmnopqrstuvwxyz"):gmatch(".") do
                pcall(vim.keymap.del, "t", l, { buffer = buf })
            end
        end, { buffer = buf, noremap = true })
    end
end

vim.keymap.set("t", "-", activar_mayuscula)       
