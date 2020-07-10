local M = {}
local xtpipeslib = require "make4ht-xtpipes"

local domfilter = require "make4ht-domfilter"

function M.prepare_parameters(settings, extensions)
  settings.tex4ht_sty_par = settings.tex4ht_sty_par ..",tei"
  settings = mkutils.extensions_prepare_parameters(extensions, settings)
  return settings
end

function M.prepare_extensions(extensions)
  return extensions
end

function M.modify_build(make)
  local process = domfilter {
    "joincharacters"
  }

  -- we use <hi> elements for characters styled using HTF fonts in TEI
  -- use the `joincharacters` DOM filter to join them
  filter_settings "joincharacters" {
    charclasses = { hi=true, mn = true}
  }

  make:match("xml$", process)
  return make
end

return M
