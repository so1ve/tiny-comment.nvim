local M = {}
local commentstring = require("tiny-comment.commentstring")

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
  local indent = current_line:match("^%s*") or ""
  local insert_index = above and cursor[1] - 1 or cursor[1]
  local inserted_line = insert_index + 1
  local lines = {}

  for _ = 1, count or 1 do
    lines[#lines + 1] = indent
  end

  vim.api.nvim_buf_set_lines(0, insert_index, insert_index, false, lines)

  local parts = commentstring.parts(inserted_line, #indent)

  if parts == nil then
    vim.api.nvim_buf_set_lines(0, insert_index, insert_index + #lines, false, {})

    return
  end

  local prefix = indent .. parts.left

  for index = 1, #lines do
    lines[index] = prefix .. parts.right
  end

  vim.api.nvim_buf_set_lines(0, insert_index, insert_index + #lines, false, lines)
  start_insert_at(inserted_line, #prefix, #lines[1])
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
  local parts = commentstring.parts(cursor[1], cursor[2])

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
