local M = {}


local filter = require "make4ht-filter"
function M.test(format)
  if format == "odt" then return false end
  return true
end

function M.prepare_parameters(params)
  params.tex4ht_sty_par = params.tex4ht_sty_par  .. ",mathml"
  return params

end
function M.modify_build(make)
  local mathjax = filter({ "mathjaxnode"}, "mathjaxnode")
  -- this extension needs mathml enabled
  make:match("html?$",mathjax)
  return make
end

return M
