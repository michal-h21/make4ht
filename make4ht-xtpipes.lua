local M = {}

local mkutils = require "mkutils"

local log = logging.new "xtpipes"
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

function M.get_selfautoparent()
  return get_texmfroot() or find_texmfroot()
end

local function replace_lg_file()
  -- xtpipes expects the lg file to be placed in the current working dir, but with the --build option,
  -- it is saved in the build dir. So we need to copy that file to the place where it is expected.
  local params = Make.params
  local basename = params.input
  local lg_name = basename .. ".lg"
  local lg_in_builddir = mkutils.file_in_builddir(lg_name,params)
  if lg_name ~= lg_in_builddir and mkutils.file_exists(lg_in_builddir) then
    log:info("Creating temporary lg_file", lg_name)
    mkutils.cp(lg_in_builddir, lg_name)
    return true, lg_name
  end
  -- don't copy the Lg file if --build_fir option isn't used
  return false, lg_name
end

function M.get_xtpipes(selfautoparent)
  -- make pattern using TeX distro path
  local pattern = string.format('java -classpath "%s/tex4ht/bin/tex4ht.jar" xtpipes -i "%s/tex4ht/xtpipes/" -o "${outputfile}" "${filename}"', selfautoparent, selfautoparent)
  -- call xtpipes on a temporary file
  local matchfunction =  function(filename)
    -- move the matched file to a temporary file, xtpipes will write it back to the original file
    local basename = mkutils.remove_extension(filename)
    local tmpfile = basename ..".tmp"
    local remove, lg_filename = replace_lg_file()
    mkutils.mv(filename, tmpfile)
    local command = pattern % {filename = tmpfile, outputfile = filename}
    log:info("execute: " ..command)
    local status, output = mkutils.execute(command)
    -- remove temporary lg file if it was created
    if remove then os.remove(lg_filename) end
    if status > 0 then
      -- if xtpipes failed to process the file, it may mean that it was bad-formed xml
      -- we can try to make it well-formed using Tidy
      local tidy_command = 'tidy -utf8 -xml -asxml -q -o "${filename}" "${tmpfile}"' % {tmpfile = tmpfile, filename = filename}
      log:warning("Xtpipes failed")
      -- show_level 1 is debug mode, which prints command output as well
      -- we need this condition to prevent multiple instances of the output
      if logging.show_level > 1 then
        print(output)
      end
      log:warning("Trying HTML tidy")
      log:debug(tidy_command)
      local status, output = os.execute(tidy_command)
      if status > 0 then
        -- if tidy failed as well, just use the original file
        -- it will probably produce corrupted ODT file though
        log:warning("Tidy failed as well")
        if logging.show_level > 1 then
          print(output)
        end
        mkutils.mv(tmpfile, filename)
      end
    end
  end
  return matchfunction
end

-- This function moves the last added file matching function to the first place
-- in the execution order. This ensures that filters are executed in the
-- correct order.
function M.move_matches(make)
  local matches = make.matches
  local last = matches[#matches]
  table.insert(matches, 1, last)
  matches[#matches] = nil
end

M.get_texmfroot = get_texmfroot
M.find_texmfroot = find_texmfroot
M.find_tex4ht_jar = find_tex4ht_jar
return M
