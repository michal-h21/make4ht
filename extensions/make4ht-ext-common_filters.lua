local M = {}


local filter = require "make4ht-filter"
local process = filter({"cleanspan-nat", "fixligatures", "hruletohr", "entities", "fix-links"}, "commonfilters")

-- filters support only html formats
function M.test(format)
  if format == "odt" then return false end
  return true
end

function M.modify_build(make)
  make:match("html?$", process)
  local matches = make.matches
  -- the filters should be first match to be executed, especially if tidy
  -- should be executed as well
  if #matches > 1 then
    local last = matches[#matches]
    table.insert(matches, 1, last)
    matches[#matches] = nil
  end
  return make
end

return M
