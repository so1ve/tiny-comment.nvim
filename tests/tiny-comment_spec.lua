local root = vim.fn.getcwd()
package.path = table.concat({
  root .. "/lua/?.lua",
  root .. "/lua/?/init.lua",
  root .. "/lua/?/?.lua",
  package.path,
}, ";")

local function assert_equal(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(
      (message or "values are not equal")
        .. "\nactual: "
        .. vim.inspect(actual)
        .. "\nexpected: "
        .. vim.inspect(expected),
      2
    )
  end
end

local function reset_buffer(lines, commentstring)
  vim.cmd.enew({ bang = true })
  vim.bo.commentstring = commentstring or "-- %s"
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

local function stop_insert()
  if vim.fn.mode():match("^[iR]") then
    vim.cmd.stopinsert()
  end
end

local function with_script_treesitter(callback)
  local original_get_parser = vim.treesitter.get_parser
  local original_get_captures_at_pos = vim.treesitter.get_captures_at_pos
  local original_get_filetypes = vim.treesitter.language.get_filetypes
  local original_get_option = vim.filetype.get_option
  local parsed = false

  local script_tree = {}

  function script_tree:contains(range)
    return parsed and range[1] == 1
  end

  function script_tree:lang()
    return "javascript"
  end

  function script_tree:children()
    return {}
  end

  local html_tree = {}

  function html_tree:parse()
    parsed = true
  end

  function html_tree:language_for_range(range)
    local is_script_body = parsed and range[1] > 0 and range[1] < vim.api.nvim_buf_line_count(0) - 1

    return is_script_body and script_tree or html_tree
  end

  function html_tree:contains(range)
    return range[1] >= 0 and range[1] <= 2
  end

  function html_tree:lang()
    return "html"
  end

  function html_tree:children()
    return parsed and { javascript = script_tree } or {}
  end

  vim.treesitter.get_parser = function()
    return html_tree
  end

  vim.treesitter.get_captures_at_pos = function()
    return {}
  end

  vim.treesitter.language.get_filetypes = function(lang)
    return { lang }
  end

  vim.filetype.get_option = function(filetype, option)
    if option ~= "commentstring" then
      return original_get_option(filetype, option)
    end

    return ({
      html = "<!-- %s -->",
      javascript = "// %s",
    })[filetype] or ""
  end

  local ok, err = pcall(callback)

  vim.treesitter.get_parser = original_get_parser
  vim.treesitter.get_captures_at_pos = original_get_captures_at_pos
  vim.treesitter.language.get_filetypes = original_get_filetypes
  vim.filetype.get_option = original_get_option

  if not ok then
    error(err, 2)
  end
end

local tiny = require("tiny-comment")
tiny.setup()

reset_buffer({ "alpha" })
tiny.insert_below()
stop_insert()
assert_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "alpha", "-- " }, "gco inserts below")

reset_buffer({ "alpha" })
tiny.insert_above()
stop_insert()
assert_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "-- ", "alpha" }, "gcO inserts above")

reset_buffer({ "alpha" })
tiny.insert_eol()
stop_insert()
assert_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "alpha -- " }, "gcA appends at end of line")

reset_buffer({ "alpha" }, "<!-- %s -->")
tiny.insert_below()
assert_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "alpha", "<!--  -->" }, "gco inserts HTML comments")
assert_equal(vim.api.nvim_win_get_cursor(0), { 2, 5 }, "gco moves the cursor inside HTML comments")

reset_buffer({ "alpha" }, "<!-- %s -->")
tiny.insert_above()
assert_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "<!--  -->", "alpha" }, "gcO inserts HTML comments")
assert_equal(vim.api.nvim_win_get_cursor(0), { 1, 5 }, "gcO moves the cursor inside HTML comments")

reset_buffer({ "alpha" }, "<!-- %s -->")
tiny.insert_eol()
assert_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "alpha <!--  -->" }, "gcA inserts HTML comments")
assert_equal(vim.api.nvim_win_get_cursor(0), { 1, 11 }, "gcA moves the cursor inside HTML comments")

with_script_treesitter(function()
  reset_buffer({ "<script>", "const x = 1", "</script>" }, "<!-- %s -->")
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  tiny.insert_below()
  stop_insert()
  assert_equal(
    vim.api.nvim_buf_get_lines(0, 0, -1, false),
    { "<script>", "const x = 1", "// ", "</script>" },
    "gco uses injected JavaScript comments inside script tags"
  )
end)

with_script_treesitter(function()
  reset_buffer({ "<script>", "const x = 1", "</script>" }, "<!-- %s -->")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  tiny.insert_below()
  stop_insert()
  assert_equal(
    vim.api.nvim_buf_get_lines(0, 0, -1, false),
    { "<script>", "// ", "const x = 1", "</script>" },
    "gco below script tags uses injected JavaScript comments"
  )
end)

with_script_treesitter(function()
  reset_buffer({ "<script>", "const x = 1", "</script>" }, "<!-- %s -->")
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  tiny.insert_above()
  stop_insert()
  assert_equal(
    vim.api.nvim_buf_get_lines(0, 0, -1, false),
    { "<script>", "const x = 1", "// ", "</script>" },
    "gcO above script close tags uses injected JavaScript comments"
  )
end)

reset_buffer({ "alpha" }, "# %s")
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("3gco<Esc>", true, false, true), "xt", false)
stop_insert()
assert_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "alpha", "# ", "# ", "# " }, "count works")
