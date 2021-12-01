local M = {}

local filter = require "make4ht-filter"

-- this extension only works for the ODT format
M.test = function(format)
  return format=="odt"
end

M.modify_build = function(make)
  local process = filter({"odttemplate"}, "odttemplate")
  make:match("4oy$", process)
  return make
end

return M
