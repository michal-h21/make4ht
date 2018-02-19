local M = {}


local filter = require "make4ht-filter"
function M.test(format)
  if format == "odt" then return false end
  return true
end

function M.modify_build(make)
  local mathjax = filter { "mathjaxnode"}
  make:match("html$",mathjax)
  return make
end

return M
