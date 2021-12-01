local M = {}


local filter = require "make4ht-filter"
function M.test(format)
  -- this extension works only for formats based on HTML, as it produces
  -- custom HTML tags that would be ilegal in XML 
  if not format:match("html5?$") then return false end
  return true
end

-- 
local detected_latex = false
function M.prepare_parameters(params)
  -- mjcli supports both MathML and LaTeX math input
  -- LaTeX math is keep if user uses "mathjax" option for make4ht
  -- "mathjax" option used in \Preamble in the .cfg file doesn't work 
  if params.tex4ht_sty_par:match("mathjax") then
    detected_latex = true
  else
    params.tex4ht_sty_par = params.tex4ht_sty_par  .. ",mathml"
  end
  return params

end
function M.modify_build(make)
  local mathjax = filter({ "mjcli"}, "mjcli")
  local params = {}
  if detected_latex then
    params.latex = true
  end
  make:match("html?$",mathjax, params)
  return make
end

return M
