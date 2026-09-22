return {
	{ "tpope/vim-fugitive" },
	{ "tpope/vim-rhubarb", dependencies = "tpope/vim-fugitive" },
	{ "julienvincent/hunk.nvim", dependencies = "MunifTanjim/nui.nvim", opts = {} },
	{ "NicolasGB/jj.nvim", opts = {} },
	{
		"ldelossa/gh.nvim",
		dependencies = { "ldelossa/litee.nvim", "nvim-lua/plenary.nvim" },
		config = function()
			require("litee.lib").setup()
			require("litee.gh").setup()
		end,
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			on_attach = function(bufnr)
				local gs = require("gitsigns")
				local function map(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end
				map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
				map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
				map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
				map("n", "<leader>gu", gs.undo_stage_hunk, "Undo staged hunk")
				map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")
				map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
				map("n", "<leader>gb", gs.blame_line, "Blame line")
				map("n", "<leader>gd", gs.diffthis, "Diff this")
				map("n", "<leader>gD", function()
					gs.diffthis("~")
				end, "Diff project")
				map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
			end,
		},
	},
	{ "folke/trouble.nvim", dependencies = "nvim-tree/nvim-web-devicons", opts = {} },
	{ "folke/todo-comments.nvim", dependencies = "nvim-lua/plenary.nvim", opts = {} },
	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup()
			require("mini.indentscope").setup()
			require("mini.bufremove").setup()
		end,
	},
	{ "tpope/vim-repeat" },
	{ "tpope/vim-surround" },
	{ "tpope/vim-unimpaired" },
	{ "tpope/vim-speeddating" },
	{ "tpope/vim-rsi" },
	{ "inkarkat/vim-ReplaceWithRegister" },
	{ "christoomey/vim-tmux-navigator" },
	{ "kana/vim-textobj-user" },
	{ "kana/vim-textobj-entire", dependencies = "kana/vim-textobj-user" },
	{ "tpope/vim-vinegar" },
	{ "nathangrigg/vim-beancount" },
	{ "jjo/vim-cue" },
	{ "ellisonleao/glow.nvim", cmd = "Glow", opts = {} },
	{ "freitass/todo.txt-vim" },
}
