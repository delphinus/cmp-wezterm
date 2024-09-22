---@class CmpWeztermWezterm
---@field callback fun(result?: string[]): nil
---@field word string
local Wezterm = {}

---@param word string
---@param callback fun(result?: string[]): nil
---@return CmpWeztermWezterm
Wezterm.new = function(word, callback)
  return setmetatable({ word = word:lower(), callback = callback }, { __index = Wezterm })
end

---@return nil
function Wezterm:gather()
  local current_pane_id = vim.env.WEZTERM_PANE
  if not current_pane_id then
    return self.callback()
  end
  self:system({ "wezterm", "cli", "list" }, function(result)
    self:fetch_panes(vim.iter(vim.gsplit(result, "\n", { plain = true })):fold({}, function(a, b)
      local win_id, tab_id, pane_id = b:match "^%s*(%d+)%s+(%d+)%s+(%d+)"
      if win_id and tab_id and pane_id and pane_id ~= current_pane_id then
        table.insert(a, pane_id)
      end
      return a
    end))
  end)
end

---@param pane_ids string[]
---@return nil
function Wezterm:fetch_panes(pane_ids)
  if #pane_ids == 0 then
    return self.callback()
  end
  local count = 0
  ---@type table<string, boolean>
  local word_map = {}
  ---@param pane_id string
  vim.iter(pane_ids):each(function(pane_id)
    self:system({ "wezterm", "cli", "get-text", "--pane-id", pane_id }, function(result)
      ---@param word string
      vim.iter(result:gmatch "[%w%d_:/.%-~]+"):each(function(word)
        if not word:lower():match(self.word) then
          return
        end
        local cleaned = word:gsub("[:.]+$", "")
        if #cleaned == 0 then
          return
        end
        word_map[cleaned] = true
        ---@param w string
        vim.iter(word:gmatch "[%w%d]+"):each(function(w)
          word_map[w] = true
        end)
      end)
      count = count + 1
      if count == #pane_ids then
        self.callback(vim.tbl_keys(word_map))
      end
    end)
  end)
end

---@param cmd string[]
---@param cb fun(result: string): nil
function Wezterm:system(cmd, cb)
  vim.system(cmd, { text = true }, function(obj)
    if obj.code == 0 then
      cb(obj.stdout)
    else
      require("cmp.utils.debug").log(("[cmp_wezterm] code: %d, stderr: %s"):format(obj.code, obj.stderr))
      self.callback()
    end
  end)
end

return {
  is_available = vim.env.TERM_PROGRAM == "WezTerm",

  ---@param word string
  ---@param callback fun(words?: string[]): nil
  start = function(word, callback)
    Wezterm.new(word, callback):gather()
  end,
}
