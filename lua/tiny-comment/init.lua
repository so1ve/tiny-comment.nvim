local M = {}

local defaults = {
  mappings = {
    below = "gco",
    above = "gcO",
    eol = "gcA",
  },
}

M.config = vim.deepcopy(defaults)

local active_mappings = {}

local function clear_mappings()
  for _, lhs in ipairs(active_mappings) do
    pcall(vim.keymap.del, "n", lhs)
  end

  active_mappings = {}
end

local function set_mapping(lhs, callback, desc)
  if lhs == nil or lhs == "" then
    return
  end

  vim.keymap.set("n", lhs, callback, { desc = desc })
  active_mappings[#active_mappings + 1] = lhs
end

local function tree_commentstring(ref_position)
  local has_parser, parser = pcall(vim.treesitter.get_parser, 0, "")

  if not has_parser or parser == nil then
    return nil
  end

  local row, col = ref_position[1] - 1, ref_position[2]
  local ref_range = { row, col, row, col + 1 }
  local captures = vim.treesitter.get_captures_at_pos(0, row, col)

  for index = #captures, 1, -1 do
    local capture = captures[index]
    local metadata = capture.metadata
    local commentstring = metadata["bo.commentstring"]
      or metadata[capture.id] and metadata[capture.id]["bo.commentstring"]

    if commentstring then
      return commentstring
    end
  end

  local commentstring
  local commentstring_level = 0

  local function traverse(language_tree, level)
    if not language_tree:contains(ref_range) then
      return
    end

    for _, filetype in ipairs(vim.treesitter.language.get_filetypes(language_tree:lang())) do
      local ok, filetype_commentstring = pcall(vim.filetype.get_option, filetype, "commentstring")

      if ok and filetype_commentstring ~= "" and level > commentstring_level then
        commentstring = filetype_commentstring
        commentstring_level = level
      end
    end

    for _, child in pairs(language_tree:children()) do
      traverse(child, level + 1)
    end
  end

  traverse(parser, 1)

  return commentstring
end

local function get_commentstring(ref_position)
  return tree_commentstring(ref_position) or vim.bo.commentstring
end

local function parse_commentstring(commentstring)
  if commentstring == nil or commentstring == "" then
    vim.notify("Option 'commentstring' is empty.", vim.log.levels.WARN)

    return nil
  end

  if not commentstring:find("%%s") then
    vim.notify(commentstring .. " is not a valid 'commentstring'.", vim.log.levels.ERROR)

    return nil
  end

  local left, right = commentstring:match("^(.-)%%s(.-)$")

  if left == nil or right == nil then
    return nil
  end

  return left, right
end

local function comment_parts(ref_position)
  local left, right = parse_commentstring(get_commentstring(ref_position))

  if left == nil or right == nil then
    return nil
  end

  return {
    left = left,
    right = right,
  }
end

local function start_insert_at(line, insert_col, line_len)
  if insert_col <= 0 then
    vim.api.nvim_win_set_cursor(0, { line, 0 })
    vim.cmd.startinsert()

    return
  end

  if insert_col >= line_len then
    vim.api.nvim_win_set_cursor(0, { line, math.max(line_len - 1, 0) })
    vim.cmd.startinsert({ bang = true })

    return
  end

  vim.api.nvim_win_set_cursor(0, { line, insert_col })
  vim.cmd.startinsert()
end

local function insert_line(above, count)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = vim.api.nvim_get_current_line()
  local parts = comment_parts({ cursor[1], cursor[2] + 1 })

  if parts == nil then
    return
  end

  local indent = current_line:match("^%s*") or ""
  local prefix = indent .. parts.left
  local lines = {}

  for _ = 1, count or 1 do
    lines[#lines + 1] = prefix .. parts.right
  end

  local insert_index = above and cursor[1] - 1 or cursor[1]
  vim.api.nvim_buf_set_lines(0, insert_index, insert_index, false, lines)
  start_insert_at(insert_index + 1, #prefix, #lines[1])
end

function M.insert_below(count)
  insert_line(false, count)
end

function M.insert_above(count)
  insert_line(true, count)
end

function M.insert_eol()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = vim.api.nvim_get_current_line()
  local parts = comment_parts({ cursor[1], cursor[2] + 1 })

  if parts == nil then
    return
  end

  local spacer = (line == "" or line:match("%s$") ~= nil) and "" or " "
  local prefix = spacer .. parts.left
  local new_line = line .. prefix .. parts.right
  vim.api.nvim_set_current_line(new_line)
  start_insert_at(cursor[1], #line + #prefix, #new_line)
end

function M.setup(opts)
  clear_mappings()
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  set_mapping(M.config.mappings.below, function()
    M.insert_below(vim.v.count1)
  end, "Add comment below")

  set_mapping(M.config.mappings.above, function()
    M.insert_above(vim.v.count1)
  end, "Add comment above")

  set_mapping(M.config.mappings.eol, M.insert_eol, "Add comment at end of line")
end

return M
