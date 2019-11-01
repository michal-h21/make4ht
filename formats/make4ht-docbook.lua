local M = {}
local mkutils = require "mkutils"
local lfs     = require "lfs"
local os      = require "os"
local kpse    = require "kpse"
local filter  = require "make4ht-filter"
local domfilter  = require "make4ht-domfilter"
local xtpipeslib = require "make4ht-xtpipes"
local log = logging.new "docbook"

function M.prepare_parameters(settings, extensions)
  settings.tex4ht_sty_par = settings.tex4ht_sty_par ..",docbook"
  settings = mkutils.extensions_prepare_parameters(extensions, settings)
  return settings
end

local move_matches = xtpipeslib.move_matches

-- call xtpipes from Lua
local function call_xtpipes(make)
  -- we must find root of the TeX distribution
  local selfautoparent = xtpipeslib.get_selfautoparent()

  if selfautoparent then
    local matchfunction = xtpipeslib.get_xtpipes(selfautoparent)
    make:match("xml$", matchfunction)
    move_matches(make)
  else
    log:warning "Cannot locate xtpipes. Try to set TEXMFROOT variable to a root directory of your TeX distribution"
  end
end

function M.modify_build(make)
  -- use xtpipes to fix some common docbook issues
  call_xtpipes(make)
  return make
end

return M
