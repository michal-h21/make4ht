local M = {}
local mkutils = require "mkutils"
local lfs     = require "lfs"
local os      = require "os"


function M.prepare_parameters(settings, extensions)
  settings.tex4ht_sty_par = settings.tex4ht_sty_par ..",ooffice"
  settings.tex4ht_par = settings.tex4ht_par .. " ooffice/! -cmozhtf"
  -- settings.t4ht_par = settings.t4ht_par .. " -cooxtpipes -coo "
  settings.t4ht_par = settings.t4ht_par .. " -cooxtpipes "
  settings = mkutils.extensions_prepare_parameters(extensions, settings)
  return settings
end

-- object for working with the ODT file
local Odtfile = {}
Odtfile.__index = Odtfile

Odtfile.new = function(archivename)
  local self = setmetatable({}, Odtfile)
  -- create temporary directory
  local tmpname = os.tmpname()
  tmpname = tmpname:match("([a-zA-Z0-9_%-]+)$")
  local status, msg = lfs.mkdir(tmpname)
  if not status then return nil, msg end
  self.archivelocation = tmpname
  self.name = archivename
  return self
end

function Odtfile:copy(src, dest)
  mkutils.copy(src, self.archivelocation .. "/" .. dest)
end

function Odtfile:pack()
-- sort output files according to their extensions
local function prepare_output_files(lgfiles)
  local groups = {}
  for _, name in ipairs(lgfiles) do
    local basename, extension = name:match("(.-)%.([^%.]+)$")
    local group = groups[extension] or {}
    table.insert(group, basename)
    groups[extension] = group
    print(basename, extension)
  end
  return groups
end

-- execute function on all files in the group
-- function fn takes current filename and table with various attributes
local function exec_group(groups, name, fn)
end

function M.modify_build(make)
  local executed = false
  -- build the ODT file. This match must be executed as a last one
  -- this will be executed as a first match, just to find the last filename 
  -- in the lgfile
  make:match(".*", function()
    -- execute it only once
    if not executed then
      -- this is list of processed files
      local lgfiles = make.lgfile.files
      -- find the last one
      local lastfile = lgfiles[#lgfiles]
      -- make match for the last file
      -- odt packing will be done here
      make:match(lastfile, function()
        local groups = prepare_output_files(make.lgfile.files)
        local odtname = groups.odt[1] .. ".odt"
        local odt,msg = Odtfile.new(odtname)
        print(odt, msg)
      end)
    end
    executed = true
  end)
  return make
end
return M
