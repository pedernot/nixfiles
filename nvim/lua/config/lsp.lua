local M = {}

local function java_home()
	local configured = vim.env.JAVA_HOME
	if configured and configured ~= "" then
		return configured
	end

	local java = vim.fn.exepath("java")
	if java == "" then
		return nil
	end
	java = vim.uv.fs_realpath(java) or vim.fn.resolve(java)
	return vim.fs.dirname(vim.fs.dirname(java))
end

local function open_definition_list(ev, options)
	local items = options.items or {}
	local item = items[1]
	local uri = item and item.user_data and item.user_data.uri
	local scheme = uri and uri:match("^([%w+.-]+):")

	if #items == 1 and scheme == "jdt" then
		local client = vim.lsp.get_clients({ bufnr = ev.buf, name = "jdtls" })[1]
		if not client then
			vim.notify("JDT language server is not attached", vim.log.levels.ERROR)
			return
		end
		client:request("java/classFileContents", { uri = uri }, function(err, result)
			if err or not result then
				vim.notify(
					"Java class loading failed: " .. (err and err.message or "no source returned"),
					vim.log.levels.ERROR
				)
				return
			end
			local bufnr = vim.uri_to_bufnr(uri)
			vim.bo[bufnr].modifiable = true
			local source = result:gsub("\r\n", "\n")
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(source, "\n", { plain = true }))
			vim.bo[bufnr].buftype = "nofile"
			vim.bo[bufnr].buflisted = true
			vim.bo[bufnr].swapfile = false
			vim.bo[bufnr].filetype = "java"
			vim.bo[bufnr].modifiable = false
			vim.api.nvim_set_current_buf(bufnr)
			local range = item.user_data.range
			if range then
				vim.api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
			end
		end, ev.buf)
		return
	end

	if #items == 1 and (scheme == "jar" or scheme == "jrt") then
		local client = vim.lsp.get_clients({ bufnr = ev.buf, name = "kotlin_lsp" })[1]
		if not client then
			vim.notify("Kotlin LSP is not attached", vim.log.levels.ERROR)
			return
		end
		client:request("workspace/executeCommand", {
			command = "decompile",
			arguments = { uri },
		}, function(err, result)
			if err or not result or not result.code then
				vim.notify(
					"Kotlin decompilation failed: " .. (err and err.message or "no source returned"),
					vim.log.levels.ERROR
				)
				return
			end
			local bufnr = vim.uri_to_bufnr(uri)
			vim.bo[bufnr].modifiable = true
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(result.code, "\n", { plain = true }))
			vim.bo[bufnr].buftype = "nofile"
			vim.bo[bufnr].buflisted = true
			vim.bo[bufnr].swapfile = false
			vim.bo[bufnr].filetype = result.language or "kotlin"
			vim.bo[bufnr].modifiable = false
			vim.api.nvim_set_current_buf(bufnr)
			local range = item.user_data.range
			if range then
				vim.api.nvim_win_set_cursor(0, { range.start.line + 1, range.start.character })
			end
		end, ev.buf)
		return
	end

	vim.fn.setqflist({}, " ", options)
	if #items == 1 then
		vim.cmd.cfirst()
	elseif #items > 1 then
		vim.cmd.copen()
	end
end

function M.setup()
	local capabilities = require("blink.cmp").get_lsp_capabilities()
	local servers = {
		"bashls",
		"cue",
		"dockerls",
		"hls",
		"jdtls",
		"lua_ls",
		"mojo",
		"nixd",
		"ruff",
		"rust_analyzer",
		"zls",
	}

	vim.lsp.config("*", { capabilities = capabilities })
	vim.lsp.config("dockerls", {
		settings = {
			docker = { languageserver = { formatter = { ignoreMultilineInstructions = true } } },
		},
	})
	vim.lsp.config("hls", {
		filetypes = { "haskell", "lhaskell", "cabal" },
		settings = {
			haskell = {
				formattingProvider = "ormolu",
				plugin = { hlint = { diagnosticsOn = false } },
			},
		},
	})
	vim.lsp.config("ty", {
		cmd = { "ty", "server" },
		filetypes = { "python" },
		root_markers = { "pyproject.toml", "ty.toml", ".git" },
		settings = { ty = { experimental = { autoImport = true, rename = true } } },
		capabilities = capabilities,
	})

	local jdk = java_home()
	local kotlin_env = vim.env.IJ_JAVA_OPTIONS or ""
	if jdk then
		kotlin_env = kotlin_env .. " -Dcom.jetbrains.ls.imports.gradle.java.home=" .. jdk
	end
	vim.lsp.config("kotlin_lsp", {
		cmd = { "kotlin-lsp", "--stdio" },
		cmd_env = { IJ_JAVA_OPTIONS = kotlin_env },
		filetypes = { "kotlin" },
		init_options = jdk and { defaultSdk = jdk } or {},
		root_markers = {
			"settings.gradle",
			"settings.gradle.kts",
			"pom.xml",
			"build.gradle",
			"build.gradle.kts",
			"workspace.json",
		},
		capabilities = capabilities,
	})

	for _, server in ipairs(servers) do
		vim.lsp.enable(server)
	end
	vim.lsp.enable("ty")
	vim.lsp.enable("kotlin_lsp")

	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
		callback = function(ev)
			vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
			local opts = { noremap = true, silent = true, buffer = ev.buf }
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
			vim.keymap.set("n", "gd", function()
				vim.lsp.buf.definition({
					on_list = function(options)
						open_definition_list(ev, options)
					end,
				})
			end, opts)
			vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
			vim.keymap.set("n", "<space>ca", vim.lsp.buf.code_action, opts)
			vim.keymap.set("n", "<space>f", function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end, opts)

			local client = vim.lsp.get_client_by_id(ev.data.client_id)
			if client and client.name == "jdtls" then
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end
		end,
	})
end

return M
