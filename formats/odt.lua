local M = {}
local mkutils = require "mkutils"
local lfs     = require "lfs"
local os      = require "os"
local kpse    = require "kpse"
local filter  = require "make4ht-filter"


function M.prepare_parameters(settings, extensions)
  settings.tex4ht_sty_par = settings.tex4ht_sty_par ..",ooffice"
  settings.tex4ht_par = settings.tex4ht_par .. " ooffice/! -cmozhtf"
  -- settings.t4ht_par = settings.t4ht_par .. " -cooxtpipes -coo "
  -- settings.t4ht_par = settings.t4ht_par .. " -cooxtpipes "
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
  -- make picture dir
  lfs.mkdir(tmpname .. "/Pictures")
  self.archivelocation = tmpname
  self.name = archivename
  return self
end

function Odtfile:copy(src, dest)
  mkutils.cp(src, self.archivelocation .. "/" .. dest)
end

function Odtfile:move(src, dest)
  mkutils.mv(src, self.archivelocation .. "/" .. dest)
end

function Odtfile:create_dir(dir)
  local currentdir = lfs.currentdir()
  lfs.chdir(self.archivelocation)
  lfs.mkdir(dir)
  lfs.chdir(currentdir)
end
  
function Odtfile:make_mimetype()
  self.mimetypename = "mimetype"
  local m = io.open(self.mimetypename, "w")
  m:write("application/vnd.oasis.opendocument.text")
  m:close()
end

function Odtfile:remove_mimetype()
  os.remove(self.mimetypename)
end


function Odtfile:pack()
  local currentdir = lfs.currentdir()
  local zip_command = mkutils.find_zip()
  lfs.chdir(self.archivelocation)
  -- make temporary mime type file
  self:make_mimetype()
  os.execute(zip_command .. " -q0X " .. self.name .. " " .. self.mimetypename)
  -- remove it, so the next command doesn't overwrite it
  self:remove_mimetype()
  os.execute(zip_command .." -r " .. self.name .. " *")
  lfs.chdir(currentdir)
  mkutils.cp(self.archivelocation .. "/" .. self.name, self.name)
  mkutils.delete_dir(self.archivelocation)
end

-- find if tex4ht.jar exists in a path
local function find_tex4ht_jar(path)
  local jar_file = path .. "/tex4ht/bin/tex4ht.jar"
  return mkutils.file_exists(jar_file)
end

-- return value of TEXMFROOT variable if it exists and if tex4ht.jar can be located inside
local function get_texmfroot()
  -- user can set TEXMFROOT environmental variable as the last resort
  local root_directories = {kpse.var_value("TEXMFROOT"), kpse.var_value("TEXMFDIST"), os.getenv("TEXMFROOT")}
  for _, root in ipairs(root_directories) do
    if root then
      if find_tex4ht_jar(root) then return root end
      -- TeX live locates files in texmf-dist subdirectory, but Miktex doesn't
      local path = root .. "/texmf-dist"
      if find_tex4ht_jar(path) then return path end
    end
  end
end

-- Miktex doesn't seem to set TeX variables such as TEXMFROOT
-- we will try to find the TeX root using trick with locating package in TeX root
-- there is a danger that this file is located in TEXMFHOME, the location will fail then
local function find_texmfroot()
  local tex4ht_path = kpse.find_file("tex4ht.sty")
  if tex4ht_path then
    local path = tex4ht_path:gsub("/tex/generic/tex4ht/tex4ht.sty$","")
    if find_tex4ht_jar(path) then return path end
  end
  return nil
end

-- call xtpipes from Lua
local function call_xtpipes(make)
  -- we must find root of the TeX distribution
  local selfautoparent = get_texmfroot() or find_texmfroot()
  if selfautoparent then
    -- make pattern using TeX distro path
    local pattern = string.format("java -classpath %s/tex4ht/bin/tex4ht.jar xtpipes -i %s/tex4ht/xtpipes/ -o ${outputfile} ${filename}", selfautoparent, selfautoparent)
    -- call xtpipes on a temporary file
    local matchfunction =  function(filename)
      -- move the matched file to a temporary file, xtpipes will write it back to the original file
      local basename = mkutils.remove_extension(filename)
      local tmpfile = basename ..".tmp"
      mkutils.mv(filename, tmpfile)
      local command = pattern % {filename = tmpfile, outputfile = filename}
      print(command)
      local status = os.execute(command)
      if status > 0 then
        -- if xtpipes failed to process the file, it may mean that it was bad-formed xml
        -- we can try to make it well-formed using Tidy
        local tidy_command = "tidy -utf8 -xml -asxml -q -o ${filename} ${tmpfile}" % {tmpfile = tmpfile, filename = filename}
        print("xtpipes failed trying tidy")
        print(tidy_command)
        local status = os.execute(tidy_command)
        if status > 0 then
          -- if tidy failed as well, just use the original file
          -- it will probably produce corrupted ODT file though
          print("Tidy failed as well")
          mkutils.mv(tmpfile, filename)
        end
      end
    end
    make:match("4oo", matchfunction)
    make:match("4om", matchfunction)
    -- is is necessary to execute the above matches as first in the build file
    local matches = make.matches
    -- move last match to a first place
    local function move_matches()
      local last = matches[#matches]
      table.insert(matches, 1, last)
      matches[#matches] = nil
    end
    -- we need to move last two matches, for 4oo and 4om files
    move_matches()
    move_matches()
  else
    print "Cannot locate xtpipes. Try to set TEXMFROOT variable to a root directory of your TeX distribution"
  end
end

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
  for _, basename in ipairs(groups[name] or {}) do
    fn{basename = basename, extension=name, filename = basename .. "." .. name}
  end
end

function M.modify_build(make)
  local executed = false
  -- execute xtpipes from the build file, instead of t4ht. this fixes issues with wrong paths
  -- expanded in tex4ht.env in Miktex or Debian
  call_xtpipes(make)
  -- convert XML entities for Unicoe characters produced by Xtpipes to characters
  local fixentities = filter {"entities-to-unicode"}
  make:match("4oo", fixentities)
  make:match("4om", fixentities)
  -- build the ODT file. This match must be executed as a last one
  -- this will be executed as a first match, just to find the last filename 
  -- in the lgfile
  make:match(".*", function()
    -- execute it only once
    if not executed then
      -- this is list of processed files
      local lgfiles = make.lgfile.files
      -- find the last one
      local lastfile = lgfiles[#lgfiles] .."$"
      -- make match for the last file
      -- odt packing will be done here
      make:match(lastfile, function()
        local groups = prepare_output_files(make.lgfile.files)
        local basename = groups.odt[1]
        local odtname = basename .. ".odt"
        local odt,msg = Odtfile.new(odtname)
        if not odt then
          print("Cannot create ODT file: " .. msg)
        end
        -- helper function for simple file moving
        local function move_file(group, dest)
          exec_group(groups, group, function(par)
            odt:move("${filename}" % par, dest)
          end)
        end

        -- the document text
        exec_group(groups, "4oo", function(par)
          odt:move("${filename}" % par, "content.xml")
          odt:create_dir("Pictures")
        end)

        -- manifest
        exec_group(groups, "4of", function(par)
          odt:create_dir("META-INF")
          odt:move("${filename}" % par, "META-INF/manifest.xml")
        end)

        -- math
        exec_group(groups, "4om", function(par)
          odt:create_dir(par.basename)
          odt:move("${filename}" % par, "${basename}/content.xml" % par)
          -- copy the settings file to math subdir
          local settings = groups["4os"][1]
          odt:copy(settings .. ".4os", "${basename}/settings.xml" % par)
        end)

        -- these files are created only once, so it doesn't matter that they are
        -- copied to one file
        move_file("4os", "settings.xml")
        move_file("4ot", "meta.xml")
        move_file("4oy", "styles.xml")

        -- pictures
        exec_group(groups, "4og", function(par)
          -- add support for images in the TEXMF tree
          if not mkutils.file_exists(par.basename) then
            par.basename = kpse.find_file(par.basename, "graphic/figure")
            if not par.basename then return nil, "Cannot find picture" end
          end
          -- the Pictues dir is flat, without subdirs
          odt:copy("${basename}" % par, "Pictures")
        end)

        -- remove some spurious file
        exec_group(groups, "4od", function(par)
          os.remove(par.filename)
        end)

        odt:pack()
      end)
    end
    executed = true
  end)
  return make
end
return M
