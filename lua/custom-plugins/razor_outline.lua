local M = {}

function M.pick()
  local fzf = require("fzf-lua")

  local src_bufnr = vim.api.nvim_get_current_buf()
  local src_file = vim.api.nvim_buf_get_name(src_bufnr)

  if src_file == nil or src_file == "" then
    vim.notify("Current buffer has no file name", vim.log.levels.ERROR)
    return
  end

  local parser = vim.treesitter.get_parser(src_bufnr, "razor")
  local root = parser:parse()[1]:root()

  local query = vim.treesitter.query.parse("razor", [[
    (razor_inherits_directive name: (identifier) @inherits)
    (razor_page_directive) @page
    (razor_if) @if
    (razor_foreach) @foreach
    (element) @tag
  ]])

  local items, seen = {}, {}

  for id, node in query:iter_captures(root, src_bufnr, 0, -1) do
    local kind = query.captures[id]
    local row, col = node:start()
    local text

    if kind == "tag" then
      local line = vim.api.nvim_buf_get_lines(src_bufnr, row, row + 1, false)[1] or ""
      local trimmed = line:gsub("^%s+", "")
      local tag = trimmed:match("^<([%w%._%-:]+)")
      if not tag then
        goto continue
      end
      if trimmed:match("^</") then
        goto continue
      end
      if not tag:match("^[A-Z]") then
        goto continue
      end
      text = "<" .. tag .. ">"
    elseif kind == "inherits" then
      text = "@inherits " .. vim.treesitter.get_node_text(node, src_bufnr)
    else
      text = (vim.api.nvim_buf_get_lines(src_bufnr, row, row + 1, false)[1] or ""):gsub("^%s+", "")
    end

    local entry = string.format("%d:%d [%s] %s", row + 1, col + 1, kind, text)

    if not seen[entry] then
      seen[entry] = true
      table.insert(items, entry)
    end

    ::continue::
  end

  table.sort(items, function(a, b)
    local la, ca = a:match("^(%d+):(%d+)")
    local lb, cb = b:match("^(%d+):(%d+)")
    la, ca, lb, cb = tonumber(la), tonumber(ca), tonumber(lb), tonumber(cb)
    if la == lb then
      return ca < cb
    end
    return la < lb
  end)

  -- use bat for preview
  local preview_cmd = table.concat({
    "bash -c",
    vim.fn.shellescape(
      [[
        line="${1%%:*}"
        ctx=8
        start=$(( line > ctx ? line - ctx : 1 ))
        stop=$(( line + ctx ))

        BAT_PAGER="" bat \
          --paging=never \
          --style=numbers \
          --color=always \
          --highlight-line "$line" \
          --line-range "${start}:${stop}" \
          "$2"
    ]]
    ),
    "-- {} " .. vim.fn.shellescape(src_file),
  }, " ")

  fzf.fzf_exec(items, {
    prompt = "RazorOutline> ",
    fzf_opts = {
      ["--preview-window"] = "up:60%",
      ["--preview"] = preview_cmd,
    },
    actions = {
      ["default"] = function(selected)
        local l, c = selected[1]:match("^(%d+):(%d+)")
        vim.api.nvim_win_set_cursor(
          src_bufnr == vim.api.nvim_get_current_buf() and 0 or vim.fn.bufwinid(src_bufnr),
          { tonumber(l), tonumber(c) - 1 }
        )
      end,
    },
  })
end

return M
