local misc = require("custom-plugins.misc")

vim.keymap.set("v", "<leader>ys", misc.slugify_visual_selection, {
  desc = "Copy selection as slug",
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "markdown",
  callback = function(event)
    vim.keymap.set("n", "<CR>", misc.toggle_markdown_checkbox, {
      buffer = event.buf,
      silent = true,
      desc = "Toggle Markdown checkbox",
    })
  end,
})
