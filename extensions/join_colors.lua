local M = {}

local filter = require "make4ht-domfilter"

-- filters support only html formats
function M.test(format)
  if format == "odt" then return false end
  return true
end

function M.modify_build(make)
  local process = filter {"joincolors"}
  make:match("html$", process)
  return make
end
return M
