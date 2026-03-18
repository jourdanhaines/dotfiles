return {
  "seblyng/roslyn.nvim",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function(_, opts)
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    capabilities.textDocument.diagnostic = { dynamicRegistration = true }

    local lsp_config = { capabilities = capabilities }

    -- On Linux, use the manually extracted language server
    if vim.uv.os_uname().sysname == "Linux" then
      local arch = vim.uv.os_uname().machine
      local platform = "linux-" .. (arch == "aarch64" and "arm64" or "x64")
      local exe = vim.fs.joinpath(
        vim.fn.expand("~"),
        ".local",
        "share",
        "csharp-ls",
        "content",
        "LanguageServer",
        platform,
        "Microsoft.CodeAnalysis.LanguageServer"
      )

      if vim.fn.executable(exe) == 1 then
        lsp_config.cmd = {
          exe,
          "--logLevel=Information",
          "--extensionLogDirectory=" .. vim.fs.dirname(vim.lsp.log.get_filename()),
          "--stdio",
        }
      end
    end

    require("roslyn").setup(opts)
    vim.lsp.config("roslyn", lsp_config)
  end,
  opts = {},
}
