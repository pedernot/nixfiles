local map = vim.keymap.set
local silent = { silent = true }

map("n", "<space>", "<Nop>")
map("n", "<leader>h", "<cmd>nohlsearch<cr><C-L>", { desc = "Clear highlights" })
map("v", ".", ":norm.<cr>", { desc = "Repeat in visual" })
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "Q", "<Nop>", { desc = "Disable Q" })
map("n", "<leader>p", ':set paste<cr>o<esc>"+]p:set nopaste<cr>', { desc = "Paste from clipboard" })

for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
	map({ "n", "i" }, key, "<Nop>")
end

map("n", "<leader>bd", "<cmd>bp<cr><cmd>bd #<cr>", { desc = "Delete buffer" })
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", vim.tbl_extend("force", silent, { desc = "Tmux left" }))
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", vim.tbl_extend("force", silent, { desc = "Tmux down" }))
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", vim.tbl_extend("force", silent, { desc = "Tmux up" }))
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", vim.tbl_extend("force", silent, { desc = "Tmux right" }))

map("n", "<space>e", vim.diagnostic.open_float, { desc = "Diagnostic float" })
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
map("n", "<space>q", vim.diagnostic.setloclist, { desc = "Diagnostic loclist" })

local commands = {
	["<C-x><C-x>"] = { "Trouble toggle", "Trouble" },
	["<C-x><C-w>"] = { "Trouble toggle diagnostics", "Trouble workspace" },
	["<C-x><C-d>"] = { "Trouble toggle diagnostics filter.buf=0", "Trouble document" },
	["<C-x><C-l>"] = { "Trouble toggle loclist", "Trouble loclist" },
	["<C-x><C-q>"] = { "Trouble toggle quickfix", "Trouble quickfix" },
	["<C-p><C-p>"] = { "Telescope", "Telescope" },
	["<C-p><C-f>"] = { "Telescope find_files", "Find files" },
	["<C-p><C-g>"] = { "Telescope live_grep", "Live grep" },
	["<C-p><C-b>"] = { "Telescope buffers", "Buffers" },
	["<C-p><C-o>"] = { "Telescope lsp_document_symbols", "Document symbols" },
	["r<C-]>"] = { "Telescope lsp_references", "References" },
	["<C-p><C-h>"] = { "Telescope oldfiles", "Old files" },
	["<C-p><C-t>"] = { "Telescope lsp_dynamic_workspace_symbols", "Workspace symbols" },
	["<C-p><C-u>"] = { "Telescope undo", "Undo history" },
}

for key, item in pairs(commands) do
	map("n", key, "<cmd>" .. item[1] .. "<cr>", { silent = true, desc = item[2] })
end
