local M = {}


local filter = require "make4ht-filter"
local process = filter {"cleanspan-nat", "fixligatures", "hruletohr", "entities", "fix-links"}


function M.modify_build(make)
  make:match("html$", process)
  return make
end

return M
