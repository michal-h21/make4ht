local M = {}
local mkutils = require "mkutils"

function M.prepare_parameters(settings, extensions)

  settings.tex4ht_sty_par = settings.tex4ht_sty_par ..",ooffice"
  settings.tex4ht_par = settings.tex4ht_par .. " ooffice/! -cmozhtf"
  settings.t4ht_par = settings.t4ht_par .. " -cooxtpipes -coo "
  -- settings = mkutils.extensions_prepare_parameters(extensions, settings)
  return settings
end
return M
