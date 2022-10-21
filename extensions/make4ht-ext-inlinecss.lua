local M = {}

local filter = require "make4ht-domfilter"

-- filters support only html formats
function M.test(format)
  if format:match("html") then return true end
  return false
end

function M.modify_build(make)
  local process = filter({"inlinecss"}, "inlinecss")
  make:match("html?$", process)
  return make
end
return M
