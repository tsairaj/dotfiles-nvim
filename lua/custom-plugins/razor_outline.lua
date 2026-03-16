local M = {}

local CAPTURE_QUERY = [[
  (razor_inherits_directive name: (identifier) @inherits)
  (razor_page_directive) @page
  (razor_if) @if
  (razor_foreach) @foreach
  (element) @tag
]]

local PREVIEW_CONTEXT = 8

local function notify_error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

local function get_current_file(bufnr)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if not file or file == "" then
    return nil
  end
  return file
end

local function get_line(bufnr, row)
  return (vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or "")
end

local function trim_left(s)
  return s:gsub("^%s+", "")
end

local function parse_position(entry)
  local line, col = entry:match("^(%d+):(%d+)")
  return tonumber(line), tonumber(col)
end

local function is_component_tag(tag)
  return tag and tag:match("^[A-Z]") ~= nil
end

local function extract_component_tag(line)
  local trimmed = trim_left(line)

  if trimmed:match("^</") then
    return nil
  end

  local tag = trimmed:match("^<([%w%._%-:]+)")
  if not is_component_tag(tag) then
    return nil
  end

  return "<" .. tag .. ">"
end

local function format_capture_text(kind, node, bufnr, row)
  if kind == "tag" then
    return extract_component_tag(get_line(bufnr, row))
  end

  if kind == "inherits" then
    local name = vim.treesitter.get_node_text(node, bufnr)
    return "@inherits " .. name
  end

  return trim_left(get_line(bufnr, row))
end

local function make_entry(kind, row, col, text)
  return string.format("%d:%d [%s] %s", row + 1, col + 1, kind, text)
end

local function sort_entries(items)
  table.sort(items, function(a, b)
    local line_a, col_a = parse_position(a)
    local line_b, col_b = parse_position(b)

    if line_a == line_b then
      return col_a < col_b
    end

    return line_a < line_b
  end)
end

local function collect_outline_items(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "razor")
  local root = parser:parse()[1]:root()
  local query = vim.treesitter.query.parse("razor", CAPTURE_QUERY)

  local items = {}
  local seen = {}

  for capture_id, node in query:iter_captures(root, bufnr, 0, -1) do
    local kind = query.captures[capture_id]
    local row, col = node:start()
    local text = format_capture_text(kind, node, bufnr, row)

    if text then
      local entry = make_entry(kind, row, col, text)

      if not seen[entry] then
        seen[entry] = true
        table.insert(items, entry)
      end
    end
  end

  sort_entries(items)
  return items
end

local function build_preview_cmd(file_path)
  local script = [[
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

  return table.concat({
    "bash -c",
    vim.fn.shellescape(script),
    "-- {} " .. vim.fn.shellescape(file_path),
  }, " ")
end

local function jump_to_entry(bufnr, entry)
  local line, col = parse_position(entry)
  if not line or not col then
    return
  end

  local target_win = 0
  if bufnr ~= vim.api.nvim_get_current_buf() then
    target_win = vim.fn.bufwinid(bufnr)
    if target_win == -1 then
      notify_error("Source buffer is not visible in any window")
      return
    end
  end

  vim.api.nvim_win_set_cursor(target_win, { line, col - 1 })
end

function M.pick()
  local fzf = require("fzf-lua")
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = get_current_file(bufnr)

  if not file_path then
    notify_error("Current buffer has no file name")
    return
  end

  local items = collect_outline_items(bufnr)
  local preview_cmd = build_preview_cmd(file_path)

  fzf.fzf_exec(items, {
    prompt = "RazorOutline> ",
    fzf_opts = {
      ["--preview-window"] = "up:60%",
      ["--preview"] = preview_cmd,
    },
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          jump_to_entry(bufnr, selected[1])
        end
      end,
    },
  })
end

return M
