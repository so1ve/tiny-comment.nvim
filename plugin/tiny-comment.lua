if vim.g.loaded_tiny_comment == 1 then
  return
end

vim.g.loaded_tiny_comment = 1

require("tiny-comment").setup()
