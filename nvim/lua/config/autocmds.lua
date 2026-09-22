local function group(name)
	return vim.api.nvim_create_augroup(name, { clear = true })
end

vim.api.nvim_create_autocmd("InsertEnter", {
	group = group("highlight_cmds"),
	callback = function()
		vim.opt_local.hlsearch = false
	end,
})
vim.api.nvim_create_autocmd("InsertLeave", {
	group = "highlight_cmds",
	callback = function()
		vim.opt_local.hlsearch = true
	end,
})
vim.api.nvim_create_autocmd("FileType", {
	group = group("format_opts"),
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})
vim.api.nvim_create_autocmd("BufRead", {
	group = group("FugitiveCustom"),
	pattern = "fugitive://*",
	callback = function()
		vim.bo.bufhidden = "delete"
	end,
})
vim.api.nvim_create_autocmd("FileType", {
	group = group("markdown_cmds"),
	pattern = "markdown",
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.formatoptions = "tqr"
	end,
})
vim.api.nvim_create_autocmd("FileType", {
	group = group("git_commit"),
	pattern = "gitcommit",
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.textwidth = 72
	end,
})
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	group = group("ansible_ft"),
	pattern = "*/playbooks/*.yml",
	command = "setfiletype yaml.ansible",
})
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	group = group("helm_ft"),
	pattern = "*.gotmpl",
	command = "setfiletype helm",
})
vim.api.nvim_create_autocmd("FileType", {
	group = group("kotlin_indent"),
	pattern = "kotlin",
	callback = function()
		vim.bo.indentexpr = "GetKotlinIndent()"
		vim.bo.expandtab = true
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 4
		vim.bo.tabstop = 4
	end,
})

vim.api.nvim_create_autocmd("Syntax", {
	group = group("after_syntax_markdown"),
	pattern = "markdown",
	callback = function()
		vim.cmd([[
      if exists("b:current_syntax") | unlet b:current_syntax | endif
      syntax include @Yaml syntax/yaml.vim
      syntax region yamlFrontmatter start=/\%^---$/ end=/^---$/ keepend contains=@Yaml
    ]])
	end,
})
vim.api.nvim_create_autocmd("Syntax", {
	group = group("after_syntax_python"),
	pattern = "python",
	callback = function()
		vim.cmd([[
      syntax match PythonKwArg "\v[\(\,]\_s?\s{-}\zs\w+\ze\=(\=)@!"
      syntax match PythonKwArg "\v^\s{-}\zs\w+\ze\=(\=)@!"
      syntax keyword PythonMatch match case
      syntax match PythonConstant /\<[A-Z_][A-Z_0-9]*\>/
      syntax match PythonDunder "__\w*__"
      highlight default link PythonKwArg Special
      highlight default link PythonConstant Constant
      highlight default link PythonDunder PreProc
      highlight default link PythonMatch Conditional
    ]])
	end,
})
