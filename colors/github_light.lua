-- Limpiar configuraciones previas
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.o.background = "light"
vim.g.colors_name = "github_light"

-- Paleta de colores exacta de GitHub Light
local github = {
  bg       = "#ffffff", -- Fondo principal
  bg_dark  = "#f6f8fa", -- Fondo para barras de estado, línea activa, etc.
  fg       = "#24292f", -- Texto normal (casi negro)
  comment  = "#57606a", -- Gris para comentarios
  keyword  = "#cf222e", -- Rojo para 'return', 'if', 'function'
  string   = "#0a3069", -- Azul oscuro para texto/strings
  func     = "#8250df", -- Morado para nombres de funciones
  variable = "#953800", -- Naranja/Marrón para variables/propiedades
  constant = "#0550ae", -- Azul brillante para constantes/números
  border   = "#d0d7de", -- Gris claro para bordes divisorios
  visual   = "#add6ff", -- Azul claro para texto seleccionado
}

-- Función auxiliar para aplicar los colores
local function hi(group, options)
  vim.api.nvim_set_hl(0, group, options)
end

-- --- GRUPOS DE RESALTADO (HIGHLIGHT GROUPS) ---

-- Editor básico
hi("Normal",       { fg = github.fg, bg = github.bg })
hi("SignColumn",   { bg = github.bg })
hi("LineNr",       { fg = github.border })
hi("CursorLine",   { bg = github.bg_dark })
hi("CursorLineNr", { fg = github.fg, bold = true })
hi("Visual",       { bg = github.visual })
hi("VertSplit",    { fg = github.border, bg = github.bg })

-- Sintaxis Estándar (Vim)
hi("Comment",  { fg = github.comment, italic = true })
hi("Constant", { fg = github.constant })
hi("String",   { fg = github.string })
hi("Function", { fg = github.func })
hi("Keyword",  { fg = github.keyword, bold = true })
hi("Statement", { fg = github.keyword })
hi("PreProc",  { fg = github.keyword })
hi("Type",     { fg = github.keyword })
hi("Special",  { fg = github.variable })

-- Soporte para TreeSitter (Neovim Moderno)
hi("@keyword",  { fg = github.keyword, bold = true })
hi("@function", { fg = github.func })
hi("@string",   { fg = github.string })
hi("@variable", { fg = github.fg })
hi("@parameter",{ fg = github.fg })
hi("@comment",  { fg = github.comment, italic = true })
hi("@constant", { fg = github.constant })
hi("@property", { fg = github.variable })
print("mi color manuel")
