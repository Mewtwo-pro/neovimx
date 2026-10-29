vim.keymap.set("n", "<CR>n", function()
    vim.cmd("belowright new")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.keymap.set("n", "-", function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local text = table.concat(lines, "\n")
        vim.fn.setreg("+", text)
        print("Buffer copiado al portapapeles")
        vim.cmd("q!")
        vim.fn.jobstart({
            "/home/manuel/Documents/pythonApps/autoMove/venv/bin/python",
            "/home/manuel/Documents/pythonApps/autoMove/movePromp.py",
        }, {
            detach = true,
        })
        vim.keymap.set("n", "<BackSpace>", function()
            vim.fn.jobstart({
                "/home/manuel/Documents/pythonApps/autoMove/venv/bin/python",
                "/home/manuel/Documents/pythonApps/autoMove/aceptPromp.py",
            }, {
                detach = true,
            })
        end, { desc = "todo el buffer", silent = true })
                    
    end, { desc = "Copiar todo el buffer", silent = true })
    
end, { desc = "Nuevo buffer vacío abajo", silent = true })
    
vim.keymap.set("n", "<CR>o", function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local text = table.concat(lines, "\n")
    vim.fn.setreg("+", text)
    print("Buffer copiado al portapapeles")
    vim.cmd("q!")
    vim.fn.jobstart({
        "/home/manuel/Documents/pythonApps/autoMove/venv/bin/python",
        "/home/manuel/Documents/pythonApps/autoMove/newPromp.py",
    }, {
        detach = true,
    })
end, { desc = "Copiar todo el buffer", silent = true })
    

