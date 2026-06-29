_G.path_filex = "manuel"
_G.name_rama = "venecia"
_G.local_switch = "init"

local input_buf, input_win
local term_buf, term_win, term_job

-- ========================
-- Abrir terminal flotante
-- ========================
local function open_terminal()
  local current_dir = vim.fn.expand('%:p:h')
  _G.path_filex = current_dir
  term_buf = vim.api.nvim_create_buf(false, true)

  term_win = vim.api.nvim_open_win(term_buf, false, {
    relative = "editor",
    width = 90,
    height = 18,
    row = 2,
    col = 5,
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

-- ========================
-- Enviar comando
-- ========================
local function send_cmd(cmd)
  vim.api.nvim_chan_send(term_job,
    "cd " .. _G.path_filex .. " && " .. cmd .. "\n"
  )

  vim.defer_fn(scroll_term_bottom, 60)
end

-- ========================
-- Cerrar todo
-- ========================
function _G.close_inputx()
  if input_win and vim.api.nvim_win_is_valid(input_win) then
    vim.api.nvim_win_close(input_win, true)
  end

  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_close(term_win, true)
  end

  _G.local_switch = "init"
  print("Proceso terminado :)")
end

-- ========================
-- Input prompt
-- ========================
--vim.api.nvim_set_keymap('v','y', '<Esc>:lua _G.input_git_net()<CR>', { noremap = true, silent = true })
function _G.input_git_net()

  open_terminal()

  input_buf = vim.api.nvim_create_buf(false, true)

  input_win = vim.api.nvim_open_win(input_buf, true, {
    relative = "editor",
    width = 45,
    height = 1,
    row = vim.o.lines - 4,
    col = 2,
    style = "minimal",
    border = "rounded",
  })

  vim.bo[input_buf].buftype = "prompt"
  vim.fn.prompt_setprompt(input_buf,
    "Git init? (Space=Yes / Enter=Exit): "
  )

  vim.keymap.set("i", "<Space>", function()
    _G.git_command()
  end, {buffer = input_buf})

  vim.keymap.set("i", "<CR>", function()
    _G.close_inputx()
  end, {buffer = input_buf})

  vim.cmd("startinsert")
end

-- ========================
-- Flujo Git
-- ========================
function _G.git_command()

  if _G.local_switch == "init" then
    send_cmd("git init")
    vim.fn.prompt_setprompt(input_buf, "Link GitHub? (Space): ")
    _G.local_switch = "link"

  elseif _G.local_switch == "link" then
    local filepath = _G.path_filex .. "/data_git.json"
    local ok, content = pcall(vim.fn.readfile, filepath)

    if not ok then
      print("No existe data_git.json")
      return
    end

    local data = vim.fn.json_decode(table.concat(content, "\n"))
    send_cmd("git remote add origin " .. data.path_url)

    vim.fn.prompt_setprompt(input_buf, "Nombre Rama: ")
    _G.local_switch = "rama"

  elseif _G.local_switch == "rama" then
    local line = vim.api.nvim_get_current_line()
    local rama = line:match(": %s*(.*)$") or "main"
    _G.name_rama = rama ~= "" and rama or "main"

    send_cmd("git checkout -b " .. _G.name_rama)
    vim.fn.prompt_setprompt(input_buf, "Add? (Space): ")
    _G.local_switch = "add"

  elseif _G.local_switch == "add" then
    local filepath = string.format("%s/data_git.json", _G.path_filex)
    local content = table.concat(vim.fn.readfile(filepath), "\n")
    local data = vim.fn.json_decode(content)
    local files = data["file_path"]
    for _, file in ipairs(files) do
      send_cmd(string.format("git add %s", file))
    end
    vim.fn.prompt_setprompt(input_buf, "Commit? (Space): ")
    _G.local_switch = "commit"

  elseif _G.local_switch == "commit" then
    send_cmd("git commit -m '" .. _G.name_rama .. "'")
    vim.fn.prompt_setprompt(input_buf, "Push? (Space): ")
    _G.local_switch = "push"

  elseif _G.local_switch == "push" then
    send_cmd("git push -u origin " .. _G.name_rama)
    vim.fn.prompt_setprompt(input_buf, "Done — Enter para cerrar")
    _G.local_switch = "done"
  end
end
    
