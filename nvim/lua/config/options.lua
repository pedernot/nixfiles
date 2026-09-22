vim.g.netrw_fastbrowse = 0
vim.g.netrw_browsex_viewer = "open"
vim.g.formatsave = true

local options = {
	number = true,
	relativenumber = true,
	cursorline = false,
	showcmd = true,
	textwidth = 100,
	wrap = false,
	termguicolors = true,
	autoread = true,
	updatetime = 100,
	tabstop = 2,
	shiftwidth = 2,
	expandtab = true,
	autoindent = true,
	incsearch = true,
	hlsearch = true,
	ignorecase = true,
	smartcase = true,
	showmatch = true,
	wildmenu = true,
	swapfile = false,
	signcolumn = "yes",
	splitbelow = true,
	splitright = true,
	hidden = true,
	completeopt = "menu,menuone,noselect",
}

for name, value in pairs(options) do
	vim.opt[name] = value
end

vim.opt.shortmess:append("I")
vim.opt.wildignore:append({
	"*.swp",
	"*~",
	"._*",
	"*.pyc",
	"__pycache__",
	"*.o",
	"*.out",
	"*.obj",
	".git",
	"*.rbc",
	"*.rbo",
	"*.class",
	".svn",
	"*.gem",
	"*.zip",
	"*.tar.gz",
	"*.tar.bz2",
	"*.rar",
	"*.tar.xz",
})

vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = false,
	severity_sort = true,
})

for name, command in pairs({ W = "w", Wq = "wq", WQ = "wq", Wqa = "wqa" }) do
	vim.api.nvim_create_user_command(name, command, {})
end
vim.api.nvim_create_user_command("SQL", "enew | setlocal buftype=nofile | setlocal filetype=pgsql", {})
