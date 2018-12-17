module(...,package.seeall)

local make4ht = require("make4ht-lib")
local mkparams = require("mkparams")
--template engine
function interp(s, tab)
	local tab = tab or {}
	return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end
--print( interp("${name} is ${value}", {name = "foo", value = "bar"}) )

function addProperty(s,prop)
	if prop ~=nil then
		return s .." "..prop
	else
		return s
	end
end
getmetatable("").__mod = interp
getmetatable("").__add = addProperty 

--print( "${name} is ${value}" % {name = "foo", value = "bar"} )
-- Outputs "foo is bar"


-- merge two tables recursively
function merge(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == "table") and (type(t1[k] or false) == "table") then
      merge(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end

function string:split(sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	self:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

function remove_extension(path)
	local found, len, remainder = string.find(path, "^(.*)%.[^%.]*$")
	if found then
		return remainder
	else
		return path
	end
end

-- 

function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

-- searching for converted images
function parse_lg(filename)
  print("Parse LG")
  local outputimages,outputfiles,status={},{},nil
  local fonts, used_fonts = {},{}
  if not file_exists(filename) then
    print("Cannot read log file: "..filename)
  else
    local usedfiles={}
    for line in io.lines(filename) do
			--- needs --- pokus.idv[1] ==> pokus0x.png --- 
      -- line:gsub("needs --- (.+?)[([0-9]+) ==> ([%a%d%p%.%-%_]*)",function(name,page,k) table.insert(outputimages,k)end)
      line:gsub("needs %-%-%- (.+)%[([0-9]+)%] ==> ([%a%d%p%.%-%_]*)",
			  function(file,page,output) 
					local rec = {
						source = file,
						page=page,
						output = output
					}
					table.insert(outputimages,rec)
				end
			)
      line:gsub("File: (.*)",  function(k) 
        if not usedfiles[k] then
          table.insert(outputfiles,k)
          usedfiles[k] = true
        end
      end)
      line:gsub("htfcss: ([^%s]+)(.*)",function(k,r)
        local fields = {}
        r:gsub("[%s]*([^%:]+):[%s]*([^;]+);",function(c,v)
          fields[c] = v
        end)
        fonts[k] = fields
      end)

      line:gsub('Font("([^"]+)","([%d]+)","([%d]+)","([%d]+)"',function(n,s1,s2,s3)
        table.insert(used_fonts,{n,s1,s2,s3})
      end)

    end
    status=true
  end
  return {files = outputfiles, images = outputimages},status
end


-- 
local cp_func = os.type == "unix" and "cp" or "copy"
-- maybe it would be better to actually move the files
-- in reality it isn't.
-- local cp_func = os.type == "unix" and "mv" or "move"
function cp(src,dest)
	local command = string.format('%s "%s" "%s"', cp_func, src, dest)
	if cp_func == "copy" then command = command:gsub("/",'\\') end
	print("Copy: "..command)
	os.execute(command)
end

function mv(src, dest)
  local mv_func = os.type == "unix" and "mv " or "move "
	local command = string.format('%s "%s" "%s"', mv_func, src, dest)
  -- fix windows paths
	if mv_func == "move" then command = command:gsub("/",'\\') end
  print("Move: ".. command)
  os.execute(command)
end

function delete_dir(path)
  local cmd = os.type == "unix" and "rm -rd " or "rd /s/q "
  os.execute(cmd .. path)
end

local used_dir = {}

function prepare_path(path)
	--local dirs = path:split("/")
	local dirs = {}
	if path:match("^/") then dirs = {""}
	elseif path:match("^~") then
		local home = os.getenv "HOME"
		dirs = home:split "/"
		path = path:gsub("^~/","")
		table.insert(dirs,1,"")
	end
	if path:match("/$")then path = path .. " " end
	for _,d in pairs(path:split "/") do
		table.insert(dirs,d)
	end
	table.remove(dirs,#dirs)
	return dirs,table.concat(dirs,"/")
end

-- Find which part of path already exists
-- and which directories have to be created
function find_directories(dirs, pos)
	local pos = pos or #dirs
	-- we tried whole path and no dir exist
	if pos < 1 then return dirs end
	local path = ""
	-- in the case of unix absolute path, empty string is inserted in dirs
	if pos == 1 and dirs[pos] == "" then
		path = "/"
	else
		path = table.concat(dirs,"/", 1,pos) .. "/"
	end
	if not lfs.chdir(path)  then -- recursion until we succesfully changed dir
	-- or there are no elements in the dir table
	return find_directories(dirs,pos - 1)
elseif pos ~= #dirs then -- if we succesfully changed dir
	-- and we have dirs to create
	local p = {}
	for i = pos+1, #dirs do
		table.insert(p, dirs[i])
	end
	return p
else  -- whole path exists
	return {}
end
end

function mkdirectories(dirs)
	if type(dirs) ~="table" then
		return false, "mkdirectories: dirs is not table"
	end
	for _,d in ipairs(dirs) do
		local stat,msg = lfs.mkdir(d)
		if not stat then return false, "makedirectories error: "..msg end
		lfs.chdir(d)
	end
	return true
end

function copy_filter(src,dest, filter)
  local src_f=io.open(src,"rb")
  local dst_f=io.open(dest,"w")
  local contents = src_f:read("*all")
  local filter = filter or function(s) return s end
  src_f:close()
  dst_f:write(filter(contents))
  dst_f:close()
end



function copy(filename,outfilename)
	local currdir = lfs.currentdir()
	if filename == outfilename then return true end
	local parts, path = prepare_path(outfilename)
	if not used_dir[path] then 
		local to_create, msg = find_directories(parts)
		if not to_create then
			print(msg)
			return false
		end
		used_dir[path] = true
		local stat, msg = mkdirectories(to_create)
		if not stat then print(msg) end
	end
	lfs.chdir(currdir)
	cp(filename, path)
	return true
end

-- find the zip command
function find_zip()
  if io.popen("zip -v","r"):close() then
    return "zip"
  elseif io.popen("miktex-zip -v","r"):close() then
    return "miktex-zip"
  end
  -- we cannot find the zip command
  return "zip"
end

-- Config loading
local function run(untrusted_code, env)
  if untrusted_code:byte(1) == 27 then return nil, "binary bytecode prohibited" end
  local untrusted_function = nil
  untrusted_function, message = load(untrusted_code, nil, "t",env)
  if not untrusted_function then return nil, message end
  if not setfenv then setfenv = function(a,b) return true end end
  setfenv(untrusted_function, env)
  return pcall(untrusted_function)
end

local main_settings = {}
main_settings.fonts = {}
local env = {}

-- We make sandbox for make script, all functions must be explicitely declared
-- Function declarations:
env.pairs  = pairs
env.ipairs = ipairs
env.print  = print
env.split  = split
env.string = string
env.table  = table
env.copy   = copy
env.tonumber = tonumber
env.tostring = tostring
env.mkdirectories = mkdirectories
env.require = require
env.texio  = texio
env.type   = type
env.lfs    = lfs
env.os     = os
env.io     = io
env.math   = math
env.unicode = unicode


-- it is necessary to use the settings table
-- set in the Make environment by mkutils
function env.set_settings(par)
  local settings = env.settings
  for k,v in pairs(par) do
    settings[k] = v
  end
end

-- Add a value to the current settings
function env.settings_add(par)
  local settings = env.settings
  for k,v in pairs(par) do
    local oldval = settings[k] or ""
    settings[k] = oldval .. v
  end
end

function env.get_filter_settings(name)
  local settings = env.settings
  -- local settings = self.params
  local filters = settings.filter or {}
  local filter_options = filters[name] or {}
  return filter_options
end

function env.filter_settings(name)
  -- local settings = Make.params
  local settings = env.settings
  local filters = settings.filter or {}
  local filter_options = filters[name] or {}
  return function(par)
    filters[name] = merge(filter_options, par)
    settings.filter = filters
  end
end
env.Font   = function(s)
  local font_name = s["name"]
  if not font_name then return nil, "Cannot find font name" end
  env.settings.fonts[font_name] = s
end

env.Make   = make4ht.Make
env.Make.params = env.settings
env.Make:add("test","test the variables:  ${tex4ht_sty_par} ${htlatex} ${input} ${config}")

-- this function reads the LaTeX log file and tries to detect fatal errors in the compilation
local function testlogfile(par)
  local logfile = par.input .. ".log"
  local f = io.open(logfile,"r")
  if not f then
    print("Make4ht: cannot open log file "..logfile)
    return 1
  end
  local len = f:seek("end")
  -- test only the end of the log file, no need to run search functions on everything
  local newlen = len - 1256
  -- but the value to seek must be greater than 0
  newlen = (newlen > 0) and newlen or 0
  f:seek("set", newlen)
  local text = f:read("*a")
  f:close()
  if text:match("No pages of output") or text:match("TeX capacity exceeded, sorry") then return 1 end
  return 0
end


-- Make this function available in the build files
Make.testlogfile = testlogfile
--env.Make:add("htlatex", "${htlatex} ${latex_par} '\\\makeatletter\\def\\HCode{\\futurelet\\HCode\\HChar}\\def\\HChar{\\ifx\"\\HCode\\def\\HCode\"##1\"{\\Link##1}\\expandafter\\HCode\\else\\expandafter\\Link\\fi}\\def\\Link#1.a.b.c.{\\g@addto@macro\\@documentclasshook{\\RequirePackage[#1,html]{tex4ht}\\let\\HCode\\documentstyle\\def\\documentstyle{\\let\\documentstyle\\HCode\\expandafter\\def\\csname tex4ht\\endcsname{#1,html}\\def\\HCode####1{\\documentstyle[tex4ht,}\\@ifnextchar[{\\HCode}{\\documentstyle[tex4ht]}}}\\makeatother\\HCode '${config}${tex4ht_sty_par}'.a.b.c.\\input ' ${input}")

-- template for calling LaTeX with tex4ht loaded
Make.latex_command = "${htlatex} ${latex_par} '\\makeatletter"..
"\\def\\HCode{\\futurelet\\HCode\\HChar}\\def\\HChar{\\ifx\"\\HCode"..
"\\def\\HCode\"##1\"{\\Link##1}\\expandafter\\HCode\\else"..
"\\expandafter\\Link\\fi}\\def\\Link#1.a.b.c.{\\g@addto@macro"..
"\\@documentclasshook{\\RequirePackage[#1,html]{tex4ht}${packages}}"..
"\\let\\HCode\\documentstyle\\def\\documentstyle{\\let\\documentstyle"..
"\\HCode\\expandafter\\def\\csname tex4ht\\endcsname{#1,html}\\def"..
"\\HCode####1{\\documentstyle[tex4ht,}\\@ifnextchar[{\\HCode}{"..
"\\documentstyle[tex4ht]}}}\\makeatother\\HCode ${tex4ht_sty_par}.a.b.c."..
"\\input \"\\detokenize{${tex_file}}\"'"

env.Make:add("htlatex",function(par)
  local command = Make.latex_command
  if os.type == "windows" then
    command = command:gsub("'",'')
  end
  command = command % par
  print("LaTeX call: "..command)
  os.execute(command)
  return testlogfile(par)
end
,{correct_exit=0})


env.Make:add("latexmk", function(par)
  local command = Make.latex_command
  par.expanded = command % par
  -- quotes in latex_command must be escaped, they cause Latexmk error
  par.expanded = par.expanded:gsub('"', '\\"')
  local newcommand = 'latexmk -latex="${expanded}" -dvi ${tex_file}' % par
  os.execute(newcommand)
  return Make.testlogfile(par)
end, {correct_exit= 0})



env.Make:add("tex4ht","tex4ht ${tex4ht_par} \"${input}.${dvi}\"", nil, 1)
env.Make:add("t4ht","t4ht ${t4ht_par} \"${input}.${ext}\"",{ext="dvi"},1)

-- enable extension in the config file
-- the following two functions must be here and not in make4ht-lib.lua
-- because of the access to env.settings
env.Make.enable_extension = function(self,name)
  table.insert(env.settings.extensions, {type="+", name=name})
end

-- disable extension in the config file
env.Make.disable_extension = function(self,name)
  table.insert(env.settings.extensions, {type="-", name=name})
end

function load_config(settings, config_name)
  local settings = settings or main_settings
  -- the extensions requested from the command line should take precedence over
  -- extensions enabled in the config file
  local saved_extensions = settings.extensions
  settings.extensions = {}
  env.settings = settings
  env.mode = settings.mode
  if config_name and not file_exists(config_name) then
    config_name = kpse.find_file(config_name, 'texmfscripts') or config_name
  end
  local f = io.open(config_name,"r")
  if not f then 
    print("Cannot open config file", config_name)
    return  env
  end
  print("Using build file", config_name)
  local code = f:read("*all")
  local fn, msg = run(code,env)
  if not fn then print(msg) end
  assert(fn)
  -- reload extensions from command line arguments for the "format" parameter
  for _,v in ipairs(saved_extensions) do
    table.insert(settings.extensions, v)
  end
  return env
end

env.Make:add("xindy", function(par)
  -- par.encoding  = par.encoding or "utf8"
  -- par.language = par.language or "english"
  par.idxfile = par.idxfile or par.input .. ".idx"
  local modules = par.modules or {par.input}
  local t = {}
  for k,v in ipairs(modules) do
    t[#t+1] = "-M ".. v
  end
  par.moduleopt = table.concat(t, " ")
  local xindy_call = "xindy -L ${language} -C ${encoding} ${moduleopt} ${idxfile}" % par
  print(xindy_call)
  return os.execute(xindy_call)
end, { language = "english", encoding = "utf8"})

local function find_lua_file(name)
  local extension_path = name:gsub("%.", "/") .. ".lua"
  return kpse.find_file(extension_path, "lua")
end

--- load the output format plugins
function load_output_format(format_name)
  local format_library =  "make4ht.formats."..format_name
  local is_format_file = find_lua_file(format_library)
  if is_format_file then 
    local format = assert(require(format_library))
    if format then
      format.prepare_extensions = format.prepare_extensions or function(extensions) return extensions end
      format.modify_build = format.modify_build or function(make) return make end
    end
    return format
  end
end

--- Execute the prepare_parameters function in list of extensions
function extensions_prepare_parameters(extensions, parameters)
  for _, ext in ipairs(extensions) do
    -- execute the extension only if it contains prepare_parameters function
    local fn = ext.prepare_parameters
    if fn then
      parameters = fn(parameters)
    end
  end
  return parameters
end

--- Modify the build sequence using extensions
-- @param extensions list of extensions 
-- @make  Make object
function extensions_modify_build(extensions, make)
  for _, ext in ipairs(extensions) do
    local fn = ext.modify_build
    if fn then
      make = fn(make)
    end
  end
  return make
end


--- load one extension
-- @param name  extension name
-- @param format current output format
function load_extension(name,format)
  -- first test if the extension exists
  local extension_library = "make4ht.extensions." .. name
  local is_extension_file = find_lua_file(extension_library)
  -- don't try to load the extension if it doesn't exist
  if not is_extension_file then return nil end
  local extension = require("make4ht.extensions.".. name)
  -- extensions can test if the current output format is supported
  local test = extension.test
  if test then
    if test(format) then 
      return extension
    end
    -- if the test fail return nil
    return nil
  end
  -- if the extension doesn't provide the test function, we will assume that
  -- it supports every output format
  return extension
end

--- load extensions
-- @param extensions table created by mkparams.get_format_extensions function
-- @param format  output type format. extensions may support only certain file
-- formats
function load_extensions(extensions, format)
  local module_names = {}
  local extension_table = {}
  local extension_sequence = {}
  -- process the extension table. it contains type field, which can enable or
  -- diable the extension
  for _, v in ipairs(extensions) do
    local enable = v.type == "+" and true or nil
    -- load extenisons in a correct order
    -- don't load extensions multiple times
    if enable and not module_names[v.name] then
      table.insert(extension_sequence, v.name)
    end
    -- the last extension request can disable it
    module_names[v.name] = enable
  end
  for _, name in ipairs(extension_sequence) do
    -- the extension can be inserted into the extension_sequence, but disabled
    -- later.
    if module_names[name] == true then
      local extension = load_extension(name,format)
      if extension then
        print("Load extension", name)
        table.insert(extension_table, extension)
      else
        print("Cannot load extension: ".. name)
      end
    end
  end
  return extension_table
end

--- add new extensions to a list of loaded extensions
-- @param added  string with extensions to be added in the form +ext1+ext2
function add_extensions(added, extensions)
  local _, newextensions = mkparams.get_format_extensions("dummyfmt" .. added)
  -- insert new extension at the beginning, in order to support disabling using
  -- the -f option
  for _, x in ipairs(extensions or {}) do table.insert(newextensions, x) end
  return newextensions
end

-- I don't know if this is clean, but settings functions won't be available
-- for filters and extensions otherwise
for k,v in pairs(env) do _G[k] = v end
