return {
	{
		"tinted-theming/tinted-vim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.tinted_colorspace = 256
			vim.cmd.colorscheme("base16-harmonic16-dark")
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		opts = {
			ensure_installed = {
				"bash",
				"dockerfile",
				"haskell",
				"java",
				"json",
				"kotlin",
				"lua",
				"markdown",
				"nix",
				"python",
				"rust",
				"sql",
				"toml",
				"yaml",
			},
			highlight = { enable = true },
			indent = { enable = true, disable = { "kotlin" } },
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"debugloop/telescope-undo.nvim",
		},
		opts = {
			defaults = {
				path_display = { "truncate" },
				vimgrep_arguments = {
					"rg",
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
					"--smart-case",
				},
				mappings = {
					i = {
						["<C-j>"] = "move_selection_next",
						["<C-k>"] = "move_selection_previous",
						["<Esc>"] = "close",
					},
				},
			},
		},
		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)
			telescope.load_extension("undo")
		end,
	},
	{ "nvim-tree/nvim-web-devicons", lazy = true },
	{
		"akinsho/bufferline.nvim",
		dependencies = "nvim-tree/nvim-web-devicons",
		opts = { options = { diagnostics = "nvim_lsp" } },
	},
	{ "nvim-lualine/lualine.nvim", dependencies = "nvim-tree/nvim-web-devicons", opts = {} },
	{
		"karb94/neoscroll.nvim",
		opts = {
			hide_cursor = false,
			mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-e>", "zt", "zz", "zb" },
		},
	},
	{ "stevearc/dressing.nvim", opts = {} },
	{ "ntpeters/vim-better-whitespace" },
}
