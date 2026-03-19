local cmd = vim.cmd

cmd("filetype plugin indent on")
cmd("syntax enable")

local function apply_theme()
	vim.o.termguicolors = true
	vim.g.tinted_colorspace = 256
	vim.cmd("colorscheme base16-harmonic16-dark")
end

apply_theme()

-- local M = require("base16-colorscheme")
-- local hi = M.highlight
-- hi.LineNr = { guifg = M.colors.base03, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.SignColumn = { guifg = M.colors.base03, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.GitGutterAdd = { guifg = M.colors.base0B, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.GitGutterChange = { guifg = M.colors.base0D, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.GitGutterDelete = { guifg = M.colors.base08, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.GitGutterChangeDelete = { guifg = M.colors.base0E, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.NormalFloat = { guifg = M.colors.base05, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.FloatBorder = { guifg = M.colors.base05, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.DiagnosticError = { guifg = M.colors.base0E, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.DiagnosticWarn = { guifg = M.colors.base08, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.DiagnosticInfo = { guifg = M.colors.base05, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.DiagnosticHint = { guifg = M.colors.base0C, guibg = M.colors.base01, gui = nil, guisp = nil }
-- hi.CmpItemAbbrDeprecated = { guifg = M.colors.base03, guibg = nil, gui = "strikethrough", guisp = nil }
-- hi.CmpItemAbbrMatch = { guifg = M.colors.base0D, guibg = nil, gui = nil, guisp = nil }
-- hi.CmpItemAbbrMatchFuzzy = { guifg = M.colors.base0D, guibg = nil, gui = nil, guisp = nil }
-- hi.CmpItemKindVariable = { guifg = M.colors.base0D, guibg = nil, gui = nil, guisp = nil }
-- hi.CmpItemKindInterface = { guifg = M.colors.base0D, guibg = nil, gui = nil, guisp = nil }
-- hi.CmpItemKindText = { guifg = M.colors.base0D, guibg = nil, gui = nil, guisp = nil }
-- hi.CmpItemAbbrKindFunction = { guifg = M.colors.base0E, guibg = nil, gui = nil, guisp = nil }
-- hi.CmpItemAbbrKindMethod = { guifg = M.colors.base0E, guibg = nil, gui = nil, guisp = nil }
-- hi.CmpItemAbbrKindKeyword = { guifg = M.colors.base05, guibg = nil, gui = nil, guisp = nil }
-- hi.CmpItemKindProperty = { guifg = M.colors.base05, guibg = nil, gui = nil, guisp = nil }
-- hi.CmpItemKindUnit = { guifg = M.colors.base05, guibg = nil, gui = nil, guisp = nil }
--
-- hi.Operator = { guifg = M.colors.base0E, guibg = nil, gui = "none", guisp = nil }
--
-- hi.TelescopeBorder = { guifg = M.colors.base03, guibg = nil, gui = "none", guisp = nil }
-- hi.TelescopePromptBorder = { guifg = M.colors.base03, guibg = nil, gui = "none", guisp = nil }
-- hi.TelescopeResultsBorder = { guifg = M.colors.base03, guibg = nil, gui = "none", guisp = nil }
-- hi.TelescopePreviewBorder = { guifg = M.colors.base03, guibg = nil, gui = "none", guisp = nil }
