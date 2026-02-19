return {
  {
    "pmizio/typescript-tools.nvim",
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      require("typescript-tools").setup({
        capabilities = capabilities,
        settings = {
          -- Expose additional typescript-tools commands as code actions
          expose_as_code_action = {
            "fix_all",
            "add_missing_imports",
            "remove_unused",
            "remove_unused_imports",
            "organize_imports",
          },
          -- Enable complete function calls (adds parentheses after completing a function)
          complete_function_calls = true,
          -- TypeScript server file preferences
          tsserver_file_preferences = {
            includeCompletionsForModuleExports = true,
            includeCompletionsForImportStatements = true,
            includeCompletionsWithSnippetText = true,
            includeAutomaticOptionalChainCompletions = true,
            includeCompletionsWithInsertText = true,
            includeCompletionsWithClassMemberSnippets = true,
            includeCompletionsWithObjectLiteralMethodSnippets = true,
          },
        },
      })
    end,
  },
}
