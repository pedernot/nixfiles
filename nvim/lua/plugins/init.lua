return {
	{ "tpope/vim-repeat" },
	{ "tpope/vim-surround" },
	{ "tpope/vim-unimpaired" },
	{ "tpope/vim-speeddating" },
	{ "tpope/vim-rsi" },
	{ "vim-scripts/ReplaceWithRegister" },
	{ "christoomey/vim-system-copy" },
	{ "christoomey/vim-tmux-navigator" },
	{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

	-- Text objects
	{ "kana/vim-textobj-entire", dependencies = { "kana/vim-textobj-user" } },

	-- -- File system
	{ "tpope/vim-vinegar" },

	-- -- Other langs
	{ "nathangrigg/vim-beancount" },
	{ "jjo/vim-cue" },
	{ "luizribeiro/vim-cooklang" },
	{ "ellisonleao/glow.nvim", branch = "main" },
	{ "freitass/todo.txt-vim" },

	-- Visuals
	{
		"nvim-lualine/lualine.nvim",
		config = function()
			require("lualine").setup({})
		end,
	},
	{
		"akinsho/bufferline.nvim",
		config = function()
			require("bufferline").setup({ options = { diagnostics = "nvim_lsp" } })
		end,
	},
	{
		"karb94/neoscroll.nvim",
		config = function()
			require("neoscroll").setup({
				hide_cursor = false,
			})
		end,
	},
	-- { "romgrk/nvim-treesitter-context" },
	{ "tinted-theming/tinted-vim" },
	{ "stevearc/dressing.nvim", opts = {} },
	{ "ntpeters/vim-better-whitespace" },
	{
		"oysandvik94/curl.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			require("curl").setup({})
		end,
	},
}
