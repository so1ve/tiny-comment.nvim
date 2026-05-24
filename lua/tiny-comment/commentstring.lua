local M = {}

local function metadata_commentstring(row, col)
  local ok, captures = pcall(vim.treesitter.get_captures_at_pos, 0, row, col)

  if not ok then
    return nil
  end

  for index = #captures, 1, -1 do
    local capture = captures[index]
    local metadata = capture.metadata or {}
    local commentstring = metadata["bo.commentstring"]
      or metadata[capture.id] and metadata[capture.id]["bo.commentstring"]

    if type(commentstring) == "string" and commentstring ~= "" then
      return commentstring
    end
  end

  return nil
end

local function filetype_commentstring(parser, row, col)
  local ok, language_tree = pcall(parser.language_for_range, parser, { row, col, row, col + 1 })

  if not ok or language_tree == nil then
    return nil
  end

  for _, filetype in ipairs(vim.treesitter.language.get_filetypes(language_tree:lang())) do
    local option_ok, commentstring = pcall(vim.filetype.get_option, filetype, "commentstring")

    if option_ok and type(commentstring) == "string" and commentstring ~= "" then
      return commentstring
    end
  end

  return nil
end

function M.get(line, col)
  local row = line - 1
  col = math.max(col or 0, 0)

  local has_parser, parser = pcall(vim.treesitter.get_parser, 0, "")

  if not has_parser or parser == nil then
    return vim.bo.commentstring
  end

  pcall(parser.parse, parser, true)

  return metadata_commentstring(row, col) or filetype_commentstring(parser, row, col) or vim.bo.commentstring
end

function M.parse(commentstring)
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

  return {
    left = left,
    right = right,
  }
end

function M.parts(line, col)
  return M.parse(M.get(line, col))
end

return M
