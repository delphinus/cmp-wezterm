# cmp-wezterm

[WezTerm](https://wezfurlong.org/wezterm/index.html) source for [nvim-cmp](https://github.com/hrsh7th/nvim-cmp).

## What's this?

This is a source for nvim-cmp to search candidates from contents of any other pane.

## Requirements

* Neovim v0.10.0
* nvim-cmp
* WezTerm

## Installation

```lua
-- This is an example for lazy.nvim
{ "delphinus/cmp-wezterm" },
```

## Configuration

```lua
require("cmp").setup {
  sources = {
    {
      name = "wezterm",
      -- default values
      option = {
        keyword_pattern = [[\w\+]],
        trigger_characters = { "." },
      },
    },
  },
}
```
## TODO

* [ ] doc
* [x] Capture only the current tab / window.
* [ ] Capture history
* [ ] Capture workspaces
* [ ] Capture clients

## See also

* [andersevenrud/cmp-tmux: Tmux completion source for nvim-cmp and nvim-compe](https://github.com/andersevenrud/cmp-tmux)
    * Some code of this plugin is derived from cmp-tmux.
