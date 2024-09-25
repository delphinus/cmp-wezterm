local config = require "cmp_wezterm.config"
local wezterm = require "cmp_wezterm.wezterm"

---@class CmpWezterm
local source = {}

---@return CmpWezterm
source.new = function()
  config.set()
  return setmetatable({}, { __index = source })
end

---@return string
source.get_debug_name = function()
  return "wezterm"
end

---@return boolean
source.is_available = function()
  return wezterm.is_available
end

---@return string
function source:get_keyword_pattern()
  return config.keyword_pattern
end

---@return string[]
function source:get_trigger_characters()
  return config.trigger_characters
end

---@param request { context: cmp.Context, offset: integer }
---@param callback fun(items?: vim.CompletedItem[]): nil
---@return nil
function source:complete(request, callback)
  local word = request.context.cursor_before_line:sub(request.offset)
  wezterm.start(word, function(words)
    callback(words and vim
      .iter(words)
      ---@param w string
      ---@param pane CmpWeztermPane
      :map(function(w, pane)
        return { word = w, label = w, labelDetails = { detail = ("%s:%s:%s"):format(pane.win, pane.tab, pane.id) } }
      end)
      :totable())
  end)
end

return source
