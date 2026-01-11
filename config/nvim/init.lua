require("config.lazy")
require("config.keymaps")

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.softtabstop = 4
vim.o.number = true
vim.o.relativenumber = true

vim.keymap.set("n", "ff", function()
	require("fzf-lua").files({
		cwd = vim.fn.getcwd(),
		git_icons = true,
		file_icons = true
	})
end, { desc = "Project Files" })

vim.keymap.set("n", "fg", function()
	require("fzf-lua").live_grep()
end, { desc = "Live Grep" })
