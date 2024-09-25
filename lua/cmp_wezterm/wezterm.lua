local config = require "cmp_wezterm.config"

---@class CmpWeztermWezterm
---@field callback fun(result?: table<string, CmpWeztermPane>): nil
---@field word string
local Wezterm = {}

---@param word string
---@param callback fun(result?: table<string, CmpWeztermPane>): nil
---@return CmpWeztermWezterm
Wezterm.new = function(word, callback)
  return setmetatable({ word = word:lower(), callback = callback }, { __index = Wezterm })
end

---@return nil
function Wezterm:gather()
  local current_pane = vim.env.WEZTERM_PANE
  if not current_pane then
    return self.callback()
  end
  self:system({ "cli", "list" }, function(result)
    local panes = vim.iter(vim.gsplit(result, "\n", { plain = true })):fold({}, function(a, b)
      local win, tab, id = b:match "^%s*(%d+)%s+(%d+)%s+(%d+)"
      if win and tab and id and id ~= current_pane then
        table.insert(a, { id = id, win = win, tab = tab })
      end
      return a
    end)
    self:fetch_panes(panes)
  end)
end

---@class CmpWeztermPane
---@field id string
---@field tab string
---@field win string

---@private
---@param panes CmpWeztermPane[]
---@return nil
function Wezterm:fetch_panes(panes)
  if #panes == 0 then
    return self.callback()
  end
  local count = 0
  ---@type table<string, CmpWeztermPane>
  local word_map = {}
  ---@param pane CmpWeztermPane
  vim.iter(panes):each(function(pane)
    self:system({ "cli", "get-text", "--pane-id", pane.id }, function(content)
      self:parse_pane(pane,word_map, content)
      count = count + 1
      if count == #panes then
        self.callback(word_map)
      end
    end)
  end)
end

---@private
---@param pane CmpWeztermPane
---@param word_map table<string, CmpWeztermPane>
---@param content string
---@return nil
function Wezterm:parse_pane(pane,word_map, content)
  ---@param word string
  vim.iter(content:gmatch "[%w%d_:/.%-~]+"):each(function(word)
    if not word:lower():match(self.word) then
      return
    end
    local cleaned = word:gsub("[:.]+$", "")
    if #cleaned == 0 then
      return
    end
    word_map[cleaned] = pane
    ---@param w string
    vim.iter(word:gmatch "[%w%d]+"):each(function(w)
      word_map[w] = pane
    end)
  end)
end

---@private
---@param cmd string[]
---@param cb fun(result: string): nil
function Wezterm:system(cmd, cb)
  table.insert(cmd, 1, config.executable)
  local ok, err = pcall(vim.system, cmd, { text = true }, function(obj)
    if obj.code == 0 then
      cb(obj.stdout)
    else
      require("cmp.utils.debug").log(("[cmp_wezterm] code: %d, stderr: %s"):format(obj.code, obj.stderr))
      self.callback()
    end
  end)
  if not ok then
    require("cmp.utils.debug").log(("[cmp_wezterm] failed to spawn: %s"):format(err))
    self.callback()
  end
end

return {
  is_available = vim.env.TERM_PROGRAM == "WezTerm",

  ---@param word string
  ---@param callback fun(words?: table<string, CmpWeztermPane>): nil
  start = function(word, callback)
    Wezterm.new(word, callback):gather()
  end,
}
