return {
	"MagicDuck/grug-far.nvim",
	opts = { headerMaxWidth = 80 },
	cmd = { "GrugFar", "GrugFarWithin" },
	keys = {
		{
			"<leader>rr",
			function()
				local grug = require("grug-far")
				local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")

				-- Get git root directory, fallback to cwd
				local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
				if git_root == "" then
					git_root = vim.fn.getcwd()
				end

				-- Check if we're in node_modules or dist
				local current_file = vim.fn.expand("%:p")
				local in_node_modules = current_file:match("/node_modules/") ~= nil
				local in_dist = current_file:match("/dist/") ~= nil

				-- Build flags (--hidden to search dotfiles)
				local flags = { "--hidden" }
				if not in_node_modules then
					table.insert(flags, "--glob=!node_modules/")
				end
				if not in_dist then
					table.insert(flags, "--glob=!dist/")
				end
				-- Exclude .git directory
				table.insert(flags, "--glob=!.git/")

				grug.open({
					transient = true,
					prefills = {
						filesFilter = ext and ext ~= "" and "*." .. ext or nil,
						paths = git_root,
						flags = table.concat(flags, " "),
					},
				})
			end,
			mode = { "n", "x" },
			desc = "Search and Replace",
		},
	},
}
