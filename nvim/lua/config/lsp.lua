vim.lsp.config("ty", {
	settings = {
		ty = {
			experimental = {
				autoImport = true,
				rename = true,
			},
		},
	},
})
vim.lsp.enable("ty")

vim.lsp.config("ruff", {
	settings = {
		organizeImports = true,
		fixAll = true,
	},
})
vim.lsp.enable("ruff")

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
})
vim.lsp.enable("lua_ls")

vim.lsp.config("dockerls", {
	settings = {
		docker = {
			languageserver = {
				formatter = {
					ignoreMultilineInstructions = true,
				},
			},
		},
	},
})
vim.lsp.enable("dockerls")

vim.lsp.config("basedpyright", {
	capabilities = {
		-- 	workspace = {
		-- 		didChangeWatchedFiles = {
		-- 			dynamicRegistration = false,
		-- 		},
		-- 	},
		textDocument = {
			publishDiagnostics = {
				tagSupport = {
					valueSet = { 2 },
				},
			},
		},
	},
	settings = {
		basedpyright = {
			disableOrganizeImports = true, -- Use ruff
			autoImportCompletions = true,
		},
		python = {
			analysis = {
				autoImportCompletions = true,
				autoSearchPaths = true,
				diagnosticMode = "openFilesOnly",
				useLibraryCodeForTypes = true,
				typeCheckingMode = "strict",
			},
		},
	},
})
-- vim.lsp.enable("basedpyright")

vim.lsp.config("pyright", {
	capabilities = {
		textDocument = {
			publishDiagnostics = {
				tagSupport = {
					valueSet = { 2 },
				},
			},
		},
	},
	settings = {
		pyright = {
			disableOrganizeImports = true, -- Use ruff
			autoImportCompletions = true,
		},
		python = {
			analysis = {
				autoImportCompletions = true,
				autoSearchPaths = true,
				diagnosticMode = "openFilesOnly",
				useLibraryCodeForTypes = true,
				typeCheckingMode = "strict",
			},
		},
	},
})
-- vim.lsp.enable("pyright")
vim.lsp.config("hls", {
	filetypes = { "haskell", "lhaskell", "cabal" },
	settings = {
		haskell = {
			cabalFormattingProvider = "cabal-fmt",
			formattingProvider = "ormolu",
			plugin = {
				hlint = {

					diagnosticsOn = false,
				},
			},
		},
	},
})
vim.lsp.enable("hls")

vim.lsp.enable("bashls")
vim.lsp.enable("hls")
vim.lsp.enable("nixd")
vim.lsp.enable("rust_analyzer")
vim.lsp.enable("cue")
vim.lsp.enable("mojo")
