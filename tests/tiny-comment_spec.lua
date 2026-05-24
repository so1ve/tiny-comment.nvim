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

reset_buffer({ "alpha" }, "# %s")
vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("3gco<Esc>", true, false, true), "xt", false)
stop_insert()
assert_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "alpha", "# ", "# ", "# " }, "count works")
