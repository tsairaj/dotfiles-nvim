local opts = {
  log_level = vim.log.levels.DEBUG,
  async = true,
  default_format_opts = {
    timeout_ms = 5000,
  },
  formatters_by_ft = {
    cs = { "csharpier" },
    css = { "prettier" },
    html = { "prettier" },
    -- csproj = { "xmlformat" },
    xml = { "csharpier" },
    -- xml = { "xmlformat" },
    caddy = { 'caddy' },
  },
  formatters = {
    -- xmlformat = {
    --   command = "xmlformat",
    --   -- args = { "--overwrite" },
    -- },
    csharpier = {
      command = "csharpier",
      args = {
        "format",
        "--write-stdout",
      },
      to_stdin = true,
    },
    caddy = {
      command = 'caddy',
      args = { 'fmt', '-' },
      stdin = true,
    },
    prettier = {
      prepend_args = {
        "--print-width",
        "160",
        "--html-whitespace-sensitivity",
        "ignore",
      },
    },
  },
  -- format_on_save = {
  --   -- These options will be passed to conform.format()
  --   timeout_ms = 500,
  --   lsp_fallback = true,
  -- },
}

require("conform").setup(opts)
