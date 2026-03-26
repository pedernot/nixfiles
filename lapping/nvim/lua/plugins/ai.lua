return {
	{
		"zbirenbaum/copilot.lua",
		config = function()
			require("copilot").setup({
				suggestion = {
					enabled = true,
					auto_trigger = true,
					accept = "<M-l>",
				},
				nes = {
					enabled = true,
					keymap = {
						accept_and_goto = "<M-u>",
						accept = false,
						dismiss = "<Esc>",
					},
				},
			})
		end,
		dependencies = {
			"copilotlsp-nvim/copilot-lsp",
			config = function()
				vim.g.copilot_nes_debounce = 500
			end,
		},
	},
	{
		"johnseth97/codex.nvim",
		lazy = true,
		keys = {
			{
				"<leader>cc",
				function()
					require("codex").toggle()
				end,
				desc = "Toggle Codex popup",
			},
		},
		opts = {
			keymaps = {}, -- disable internal mapping
			border = "rounded", -- or 'double'
			width = 0.8,
			height = 0.8,
			autoinstall = true,
		},
	},
	{
		"yetone/avante.nvim",
		event = "VeryLazy",
		version = false,
		opts = {
			provider = "codex",
			acp_providers = {
				["codex"] = {
					command = "npx",
					args = { "@zed-industries/codex-acp" },
					env = {
						NODE_NO_WARNINGS = "1",
						OPENAI_API_KEY = os.getenv("OPENAI_API_KEY"),
					},
				},
			},
		},
		build = "make",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"stevearc/dressing.nvim",
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			{
				-- Make sure to set this up properly if you have lazy=true
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "Avante" },
				},
				ft = { "markdown", "Avante" },
				config = function()
					require("render-markdown").setup()
					vim.api.nvim_create_autocmd("FileType", {
						pattern = "markdown",
						callback = function(event)
							vim.treesitter.start(event.buf, "markdown")
						end,
					})
				end,
			},
		},
	},
}
