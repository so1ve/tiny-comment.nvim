# tiny-comment.nvim

Add the missing `gco`, `gcO`, and `gcA` comment insertion mappings without replacing your comment operator.

## Why

Neovim has built-in `gc` and `gcc` mappings, and `mini.comment` provides a compact toggle/comment textobject implementation. Neither one ships `gco`, `gcO`, or `gcA`.

tiny-comment.nvim fills only that gap:

- `gco` inserts a commented line below and enters Insert mode
- `gcO` inserts a commented line above and enters Insert mode
- `gcA` appends a comment at the end of the current line and enters Insert mode
- `[count]gco` and `[count]gcO` insert multiple commented lines

## Requirements

- Neovim 0.10+

## Installation

### `lazy.nvim`

```lua
{
  "so1ve/tiny-comment.nvim",
}
```

## Usage

With the default setup, the plugin registers the mappings automatically when it loads:

```vim
gco
gcO
gcA
```

Use it next to Neovim's built-in comments:

```lua
-- Neovim keeps these:
-- gc, gcc

-- tiny-comment.nvim adds these:
-- gco, gcO, gcA
```

Or next to `mini.comment`; it keeps owning `gc` and `gcc` while tiny-comment only adds the insertion maps:

```lua
require("mini.comment").setup()
require("tiny-comment").setup()
```

## Configuration

```lua
require("tiny-comment").setup({
  mappings = {
    below = "gco",
    above = "gcO",
    eol = "gcA",
  },
})
```

## API

### `setup(opts?)`

Registers the configured mappings.

```lua
require("tiny-comment").setup({})
```

### `insert_below()`

Insert a commented line below the current line and enter Insert mode.

```lua
require("tiny-comment").insert_below()
```

### `insert_above()`

Insert a commented line above the current line and enter Insert mode.

```lua
require("tiny-comment").insert_above()
```

### `insert_eol()`

Append a comment to the end of the current line and enter Insert mode.

```lua
require("tiny-comment").insert_eol()
```

## Notes

tiny-comment.nvim intentionally does not implement comment toggling. Use Neovim's built-in comment mappings or `mini.comment` for `gc`, `gcc`, Visual `gc`, and comment textobjects.

tiny-comment.nvim uses the current buffer's `commentstring`, with a small Tree-sitter-aware fallback for injected languages.

## Development

```bash
stylua lua plugin tests
nvim --headless -u NONE -l tests/tiny-comment_spec.lua
```

## 📝 License

[MIT](./LICENSE). Made with ❤️ by [Ray](https://github.com/so1ve)
