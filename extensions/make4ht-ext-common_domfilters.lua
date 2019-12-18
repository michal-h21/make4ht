local M = {}


-- this variable will hold the output format name
local current_format 

local filter = require "make4ht-domfilter"
-- local process = filter {"fixinlines", "idcolons", "joincharacters" }

-- filters support only html formats
function M.test(format)
  current_format = format
  -- if format == "odt" then return false end
  return true
end

function M.modify_build(make)
  -- number of filters that should be moved to the beginning
  local count = 0
  if current_format == "odt" then
    -- some formats doesn't make sense in the ODT format
    local process = filter {"joincharacters", "mathmlfixes"}
    local charclasses = {mn = true, ["text:span"] = true, mi=true}
    make:match("4oo$", process, {charclasses= charclasses})
    -- match math documents
    make:match("4om$", process, {charclasses= charclasses})
    count = 2
  else
    local process = filter {"fixinlines", "idcolons", "joincharacters", "mathmlfixes", "tablerows","booktabs"}
    make:match("html$", process)
    count = 1
  end
  return make
end

return M
