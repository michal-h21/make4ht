kpse.set_program_name("luatex")
local mkutils=require("mkutils")
local dirs = {"","home","mint","pokus","ahoj"}
print(table.concat(dirs,"/"))
for _,d in pairs(dirs) do
  local stat = lfs.chdir(d)
	if not stat then 
		print ("Directory doesn't extsit: "..d)
		--local  mkstat =lfs.mkdir(d)
	end
end
if lfs.chdir("/home/mint/Downloads") then print "Májme downloads" else print "Nemáme downloads" end

local function prepare_path(path)
	--local dirs = path:split("/")
	local dirs = {}
	if path:match("^/") then dirs = {""}
	elseif path:match("^~") then 
		local home = os.getenv "HOME"
		dirs = home:split "/"
		path = path:gsub("^~/","")
		table.insert(dirs,1,"")
	end
	for _,d in pairs(path:split "/") do
		table.insert(dirs,d)
	end
	table.remove(dirs,#dirs)
	print(table.concat(dirs,"/"))
	return dirs
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
    path = table.concat(dirs,"/", 1,pos)
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

function test(dir,pos)
	print("Create path: "..dir)
	local dirs= prepare_path(dir)
	local stat,msg = find_directories(dirs,pos)
	if not stat then print(msg) end
	print("Soucasny adresar: "..lfs.currentdir())
	if type(stat) == "table" then print("Vytvorit adresar: "..table.concat(stat,"/")) else print "neni tabuzlka" end
	stat, msg = mkdirectories(stat)
	if not stat then print(msg) end
end

prepare_path("ahoj/svete")
prepare_path("d:/ahoj/aaa/")
prepare_path("/ss/ssss")
prepare_path("~/sss/ahoj.sss")
prepare_path("~/ahoj.sss")

lfs.chdir(arg[0])
print("Adresar pred vytvarenim: " ..lfs.currentdir())
test("ahoj/svete/aaaa.j")
--test("~/ahoj/svete/aaa.kk")
test("/sss/aaaa/aaq.aaa")
test("~/Downloads/aaaaa.sss")
