local M = {}
local mkutils = require "mkutils"
local lfs     = require "lfs"
local os      = require "os"
local kpse    = require "kpse"
local filter  = require "make4ht-filter"
local domfilter  = require "make4ht-domfilter"
local domobject  = require "luaxml-domobject"
local xtpipeslib = require "make4ht-xtpipes"
local log = logging.new "odt"


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
  -- create a temporary file
  local tmpname = os.tmpname()
  -- remove a temporary file, we are interested only in the unique file name
  os.remove(tmpname)
  -- get the unique dir name
  tmpname = tmpname:match("([a-zA-Z0-9_%-%.]+)$")
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
  mkutils.execute(zip_command .. ' -q0X "' .. self.name .. '" ' .. self.mimetypename)
  -- remove it, so the next command doesn't overwrite it
  self:remove_mimetype()
  mkutils.execute(zip_command ..' -r "' .. self.name .. '" *')
  lfs.chdir(currentdir)
  mkutils.cp(self.archivelocation .. "/" .. self.name, self.name)
  mkutils.delete_dir(self.archivelocation)
end

--- *************************
--  *** fix picture sizes ***
--  *************************
--
local function add_points(dimen)
  if type(dimen) ~= "string" then return dimen end
  -- convert SVG dimensions to points if only number is provided
  if dimen:match("[0-9]$") then return dimen .. "pt" end
  return dimen
end

local function get_svg_dimensions(filename) 
  local width, height
  if mkutils.file_exists(filename) then 
    for line in io.lines(filename) do
      width = line:match("width%s*=%s*[\"'](.-)[\"']") or width
      height = line:match("height%s*=%s*[\"'](.-)[\"']") or height
      -- stop parsing once we get both width and height
      if width and height then break end
    end
  end
  width = add_points(width)
  height = add_points(height)
  return width, height
end

local function get_xbb_dimensions(filename)
  local f = io.popen("ebb -x -O " .. filename)
  if f then
    local content = f:read("*all")
    local width, height = content:match("%%BoundingBox: %d+ %d+ (%d+) (%d+)")
    return add_points(width), add_points(height)
  end
  return nil
end
--
local function fix_picture_sizes(tmpdir)
  local filename = tmpdir .. "/content.xml"
  local f = io.open(filename, "r")
  if not f then 
    log:warning("Cannot open ", filename, "for picture size fixes")
    return nil
  end
  local content = f:read("*all") or ""
  f:close()
  local status, dom= pcall(function()
    return domobject.parse(content)
  end)
  if not status then 
    log:warning("Cannot parse DOM, the resulting ODT file will be most likely corrupted")
    return nil
  end
  for _, pic in ipairs(dom:query_selector("draw|image")) do
    local imagename = pic:get_attribute("xlink:href")
    -- update SVG images dimensions
    log:debug("image", imagename)
    local parent = pic:get_parent()
    local width =  parent:get_attribute("svg:width")
    local height = parent:get_attribute("svg:height")
    -- if width == "0.0pt" then width = nil end
    -- if height == "0.0pt" then height = nil end
    if not width or not height then
      local imgfilename = tmpdir .. "/" .. imagename
      if imagename:match("svg$") then
        width, height = get_svg_dimensions(imgfilename) --  or width, height
      elseif imagename:match("png$") or imagename:match("jpe?g$") then
        width, height = get_xbb_dimensions(imgfilename)
      end
    end
    log:debug("new dimensions", width, height)
    parent:set_attribute("svg:width", width)
    parent:set_attribute("svg:height", height)
    -- if 
  end
  -- save the modified DOM again
  log:debug("Fixed picture sizes")
  local content = dom:serialize()
  local f = io.open(filename, "w")
  f:write(content)
  f:close()
end

-- fix font records in the lg file that don't correct Font_Size record
local lg_fonts_processed=false
local patched_lg_fonts = {}
local function fix_lgfile_fonts(ignored_name, params)
  -- this function is called from file match. we must use the name of the .lg file
  local filename = mkutils.file_in_builddir(params.input .. ".lg", params)
  if not lg_fonts_processed then
    local lines = {}
    -- default font_size
    local font_size = "10"
    if mkutils.file_exists(filename) then 
      -- 
      for line in io.lines(filename) do
        -- default font_size can be set in the .lg file
        if line:match("Font_Size") then
          font_size = line:match("Font_Size:%s*(%d+)")
        elseif line:match("Font%(") then
          -- match Font record
          local name, size, size2, size3 = line:match('Font%("([^"]+)","([%d]*)","([%d]+)","([%d]+)"')
          -- find if the first size is not set, and add the default font_size then
          if size == "" then
            line = string.format('Font("%s","%s","%s","%s")', name, font_size, size2, size3)
            -- we must also save the font name and size for later post-processing, because 
            -- we will need to fix styles in content.xml too
            patched_lg_fonts[name .. "-" .. font_size] = true
          end
        end
        lines[#lines+1] = line
      end
      -- save changed lines to the lg file
      local f = io.open(filename, "w")
      for _,line in ipairs(lines) do
        f:write(line .. "\n")
      end
      f:close()
    end
    filter_settings "odtfonts" {patched_lg_fonts = patched_lg_fonts}
  end
  lg_fonts_processed=true
  return true
end

local move_matches = xtpipeslib.move_matches

local function insert_lgfile_fonts(make)
  local params = make.params
  local first_file = mkutils.file_in_builddir(params.input .. ".4oo", params)
  -- find the last file and escape it so it can be used 
  -- in filename match
  make:match(first_file, fix_lgfile_fonts)
  move_matches(make)
end

-- escape string to be used in the gsub search
local function escape_file(filename)
  local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
  return filename:gsub(quotepattern, "%%%1")
end


-- call xtpipes from Lua
local function call_xtpipes(make)
  -- we must find root of the TeX distribution
  local selfautoparent = xtpipeslib.get_selfautoparent()

  if selfautoparent then
    local matchfunction = xtpipeslib.get_xtpipes(selfautoparent)
    make:match("4oo", matchfunction)
    make:match("4om", matchfunction)
    -- move last match to a first place
    -- we need to move last two matches, for 4oo and 4om files
    move_matches(make)
    move_matches(make)
    -- fix font records in the lg file
    insert_lgfile_fonts(make)
  else
    log:warning "Cannot locate xtpipes. Try to set TEXMFROOT variable to a root directory of your TeX distribution"
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
    log:debug("prepare output file", basename, extension)
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

-- remove <?xtpipes XML instructions, because they cause issues in some ODT processing
-- applications
local function remove_xtpipes(text)
  -- remove <?x
  return text:gsub("%<%?xtpipes.-%?%>", "")
end

function M.modify_build(make)
  local executed = false
  -- execute xtpipes from the build file, instead of t4ht. this fixes issues with wrong paths
  -- expanded in tex4ht.env in Miktex or Debian
  call_xtpipes(make)
  -- fix the image dimensions wrongly set by xtpipes
  local domfilters = domfilter({"t4htlinks", "odtpartable"}, "odtfilters")
  make:match("4oo$", domfilters)
  -- execute it before xtpipes, because we don't want xtpipes to mess with t4htlink elements
  move_matches(make)
  -- fixes for mathml
  local mathmldomfilters = domfilter({"joincharacters","mathmlfixes"}, "mathmlfilters")
  make:match("4om$", mathmldomfilters)
  -- DOM filters that should be executed after xtpipes
  local latedom = domfilter({"odtfonts"}, "lateodtfilters")
  make:match("4oo$", latedom)
  -- convert XML entities for Unicode characters produced by Xtpipes to characters
  local fixentities = filter {"entities-to-unicode", remove_xtpipes}
  make:match("4oo", fixentities)
  make:match("4om", fixentities)
  -- we must handle outdir. make4ht copies the ODT file before it was packed, so
  -- we will copy it again after packing later in this format file
  local outdir = make.params["outdir"]

  -- build the ODT file. This match must be executed as a last one
  -- this will be executed as a first match, just to find the last filename 
  -- in the lgfile
  make:match(".*", function()
    -- execute it only once
    if not executed then
      -- this is list of processed files
      local lgfiles = make.lgfile.files
      -- find the last file and escape it so it can be used 
      -- in filename match
      local lastfile = escape_file(lgfiles[#lgfiles]) .."$"
      -- make match for the last file
      -- odt packing will be done here
      make:match(lastfile, function(filename, par)
        local groups = prepare_output_files(make.lgfile.files)
        -- we must remove any path from the basename
        local basename = groups.odt[1]:match("([^/]+)$")
        local odtname = basename .. ".odt"
        local odt,msg = Odtfile.new(odtname)
        if not odt then
          log:error("Cannot create ODT file: " .. msg)
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

        -- fix picture sizes in the content file
        fix_picture_sizes(odt.archivelocation)

        -- remove some spurious file
        exec_group(groups, "4od", function(par)
          os.remove(par.filename)
        end)

        odt:pack()
        if outdir and outdir ~= "" then
          local filename = odt.name
          local outfilename = outdir .. "/" .. filename
          log:info("Copying ODT file to the output dir: " .. outfilename)
          mkutils.copy(filename,outfilename)
        end
      end)
    end
    executed = true
  end)
  return make
end
return M
