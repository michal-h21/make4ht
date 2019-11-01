local M = {}
local xtpipeslib = require "make4ht-xtpipes"

function M.prepare_parameters(settings, extensions)
  settings.tex4ht_sty_par = settings.tex4ht_sty_par ..",tei"
  settings = mkutils.extensions_prepare_parameters(extensions, settings)
  return settings
end

function M.prepare_extensions(extensions)
  return extensions
end

return M
