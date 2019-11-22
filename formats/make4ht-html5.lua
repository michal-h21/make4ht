local M = {}

local mkutils = require "mkutils"

function M.prepare_extensions(extensions)
  return mkutils.add_extensions("+common_domfilters", extensions)
end

function M.prepare_parameters(parameters,extensions)
  parameters.tex4ht_sty_par  = parameters.tex4ht_sty_par .. ",html5"
  parameters = mkutils.extensions_prepare_parameters(extensions,parameters)
  return parameters
end


return M
