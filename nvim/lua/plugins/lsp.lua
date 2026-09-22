return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		opts = {
			keymap = { preset = "enter", ["<Tab>"] = { "accept", "fallback" } },
			sources = { default = { "lsp", "buffer", "path", "snippets" } },
			cmdline = { sources = { "path", "cmdline" } },
			completion = {
				list = { selection = { preselect = false, auto_insert = true } },
				accept = { auto_brackets = { enabled = false } },
				documentation = { auto_show = true },
			},
			signature = { enabled = true },
		},
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp", "folke/lsp-colors.nvim" },
		config = function()
			require("config.lsp").setup()
		end,
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_organize_imports", "ruff_format" },
				nix = { "alejandra" },
				rust = { "rustfmt" },
				haskell = { "ormolu" },
				kotlin = {},
			},
			format_on_save = function(bufnr)
				if not vim.g.formatsave or vim.b[bufnr].disableFormatSave then
					return
				end
				return {
					lsp_format = "fallback",
					timeout_ms = vim.bo[bufnr].filetype == "kotlin" and 5000 or 500,
				}
			end,
		},
	},
	{
		"nvimtools/none-ls.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		config = function()
			local null_ls = require("null-ls")
			local sources = { null_ls.builtins.diagnostics.hadolint }
			if null_ls.builtins.diagnostics.statix then
				table.insert(sources, null_ls.builtins.diagnostics.statix)
			end
			null_ls.setup({ sources = sources })
		end,
	},
	{
		"lewis6991/hover.nvim",
		config = function()
			require("hover").setup({
				init = function()
					require("hover.providers.lsp")
				end,
				preview_opts = { border = nil },
				title = true,
				providers = {
					{ module = "hover.providers.lsp", priority = 1001 },
					{ module = "hover.providers.diagnostic", priority = 1000 },
				},
			})
			vim.keymap.set("n", "<C-y>", require("hover").hover, { desc = "Hover" })
		end,
	},
}
