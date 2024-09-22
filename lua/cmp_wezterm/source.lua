local wezterm = require "cmp_wezterm.wezterm"
local cmp_config = require "cmp.config"
local debug = require "cmp.utils.debug"

local default_config = {
  keyword_pattern = [[\w\+]],
  label = "[wez]",
  trigger_characters = { "." },
}

local source = {}

source.new = function()
  local cfg = cmp_config.get_source_config "wezterm"
  return setmetatable({
    config = vim.tbl_extend("force", default_config, cfg or {}),
  }, { __index = source })
end

source.get_debug_name = function()
  return "wezterm"
end

source.is_available = function()
  return wezterm.is_available
end

function source:get_keyword_pattern()
  return self.config.keyword_pattern
end

function source:get_trigger_characters()
  return self.config.trigger_characters
end

function source:complete(request, callback)
  debug.log "start"
  local word = request.context.cursor_before_line:sub(request.offset)
  wezterm
    .new(word, function(words)
      callback(words and vim
        .iter(words)
        :map(function(v)
          return { word = v, label = v, labelDetails = { detail = self.config.label } }
        end)
        :totable())
    end)
    :gather()
end

return source
