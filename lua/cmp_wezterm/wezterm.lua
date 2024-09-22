local debug = require "cmp.utils.debug"

local Wezterm = { is_available = vim.env.TERM_PROGRAM == "WezTerm" }

Wezterm.new = function(word, callback)
  return setmetatable({ word = word:lower(), callback = callback }, { __index = Wezterm })
end

function Wezterm:gather()
  local current_pane_id = vim.env.WEZTERM_PANE
  if not current_pane_id then
    return self.callback()
  end
  debug.log "[cmp_wezterm] start"
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

function Wezterm:fetch_panes(pane_ids)
  if #pane_ids == 0 then
    return self.callback()
  end
  local count = 0
  local word_map = {}
  vim.iter(pane_ids):each(function(pane_id)
    self:system({ "wezterm", "cli", "get-text", "--pane-id", pane_id }, function(result)
      vim.iter(result:gmatch "[%w%d_:/.%-~]+"):each(function(word)
        if word:lower():match(self.word) then
          local cleaned = word:gsub("[:.]+$", "")
          if #cleaned > 0 then
            word_map[cleaned] = true
            vim.iter(word:gmatch "[%w%d]+"):each(function(ww)
              word_map[ww] = true
            end)
          end
        end
      end)
      count = count + 1
      if count == #pane_ids then
        self.callback(vim.tbl_keys(word_map))
      end
    end)
  end)
end

function Wezterm:system(cmd, cb)
  vim.system(cmd, { text = true }, function(obj)
    if obj.code == 0 then
      cb(obj.stdout)
    else
      debug.log(("[cmp_wezterm] code: %d, stderr: %s"):format(obj.code, obj.stderr))
      self.callback()
    end
  end)
end

return Wezterm
