return {
  "seblyng/roslyn.nvim",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function(_, opts)
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    capabilities.textDocument.diagnostic = { dynamicRegistration = true }
    vim.lsp.config("roslyn", {
      capabilities = capabilities,
    })
    require("roslyn").setup(opts)
  end,
  opts = {},
}
