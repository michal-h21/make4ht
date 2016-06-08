module(...,package.seeall)

local make4ht = require("make4ht-lib")
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
	for _,d in pairs(dirs) do
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

-- Config loading
local function run(untrusted_code, env)
	if untrusted_code:byte(1) == 27 then return nil, "binary bytecode prohibited" end
	local untrusted_function = nil
	if not loadstring then  
		untrusted_function, message = load(untrusted_code, nil, "t",env)
	else
		untrusted_function, message = loadstring(untrusted_code)
	end
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
env.mkdirectories = mkdirectories
env.require = require
env.texio  = texio
env.type   = type
env.lfs    = lfs
env.os     = os
env.io     = io
env.unicode = unicode
env.Font   = function(s)
	local font_name = s["name"]
	if not font_name then return nil, "Cannot find font name" end
	env.settings.fonts[font_name] = s
end

env.Make   = make4ht.Make
env.Make.params = env.settings
env.Make:add("test","no takže ${tex4ht_sty_par} ${htlatex} ${input} ${config}")
--env.Make:add("htlatex", "${htlatex} ${latex_par} '\\\makeatletter\\def\\HCode{\\futurelet\\HCode\\HChar}\\def\\HChar{\\ifx\"\\HCode\\def\\HCode\"##1\"{\\Link##1}\\expandafter\\HCode\\else\\expandafter\\Link\\fi}\\def\\Link#1.a.b.c.{\\g@addto@macro\\@documentclasshook{\\RequirePackage[#1,html]{tex4ht}\\let\\HCode\\documentstyle\\def\\documentstyle{\\let\\documentstyle\\HCode\\expandafter\\def\\csname tex4ht\\endcsname{#1,html}\\def\\HCode####1{\\documentstyle[tex4ht,}\\@ifnextchar[{\\HCode}{\\documentstyle[tex4ht]}}}\\makeatother\\HCode '${config}${tex4ht_sty_par}'.a.b.c.\\input ' ${input}")
env.Make:add("htlatex",function(par) 
	local command = 
"${htlatex} ${latex_par} '\\makeatletter"..
"\\def\\HCode{\\futurelet\\HCode\\HChar}\\def\\HChar{\\ifx\"\\HCode"..
"\\def\\HCode\"##1\"{\\Link##1}\\expandafter\\HCode\\else"..
"\\expandafter\\Link\\fi}\\def\\Link#1.a.b.c.{\\g@addto@macro"..
"\\@documentclasshook{\\RequirePackage[#1,html]{tex4ht}${packages}}"..
"\\let\\HCode\\documentstyle\\def\\documentstyle{\\let\\documentstyle"..
"\\HCode\\expandafter\\def\\csname tex4ht\\endcsname{#1,html}\\def"..
"\\HCode####1{\\documentstyle[tex4ht,}\\@ifnextchar[{\\HCode}{"..
"\\documentstyle[tex4ht]}}}\\makeatother\\HCode ${tex4ht_sty_par}.a.b.c."..
"\\input ${tex_file}'" 
  if os.type == "windows" then
    command = command:gsub("'",'')
  end
  command = command % par
  print("LaTeX call: "..command)
  os.execute(command)
	local logfile = par.input .. ".log"
	local f = io.open(logfile,"r")
	if not f then 
		print("Make4ht: cannot open log file "..logfile)
		return 1
	end
	local len = f:seek("end")

	f:seek("set", len - 256)
	local text = f:read("*a")
	f:close()
	if text:match("No pages of output") then return 1 end
	return 0 
end
,{correct_exit=0})
env.Make:add("tex4ht","tex4ht ${tex4ht_par} \"${input}.${dvi}\"", nil, 1)
env.Make:add("t4ht","t4ht ${t4ht_par} \"${input}.${ext}\"",{ext="dvi"},1)

function load_config(settings, config_name)
	local settings = settings or main_settings
	env.settings = settings
	env.mode = settings.mode
	local config_name = kpse.find_file(config_name, 'texmfscripts') or config_name
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
	return env
end


