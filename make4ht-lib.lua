-- Simple make system for tex4ht
--kpse.set_program_name("luatex")
module("make4ht",package.seeall)

Make = {}
--Make.params = {}
Make.build_seq = {}
-- Patterns for matching output filenames
Make.matches = {}

Make.add = function(self,name,fn,par)
	local par = par or {}
	local params = self.params or {}
	for k,v in pairs(par) do params[k] = v; print("setting param "..k) end
	Make[name] = function(self,p,typ)
		local typ = typ or "make"
		local p = p or {}
		local fn = fn
		for k,v in pairs(p) do
			params[k]=v
		end
		-- print( fn % params)
		local command = {
			name=name,
			type=typ,
			command = fn,
			params = params
		}
		table.insert(self.build_seq,command)
	end
end

Make.length = function(self)
	return #self.build_seq
end

Make.match = function(self, pattern, command, params) 
	local params = params or {}
  self.matches[pattern] = {command = command, params = params}
end

Make.run_command = function(self,filename,s)
	local command = s.command
	local params  = s.params
	params["filename"] = filename
	print("parse_lg process file: "..filename)
	--for k,v in pairs(params) do print(k..": "..v) end
	if type(command) == "function" then
		return command(filename,params)
	elseif type(command) == "string" then
		local run = command % params
		print("Execute: " .. run)
    return os.execute(run)
	end
	return false, "parse_lg: Command is not string or function"
end


Make.image_convert =  function(self, images)
end

Make.file_matches = function(self, files)
	local statuses = {}
	-- First make params for all matchers
	for k,v in pairs(self.matches) do
		local v = self.matches[k]
		local p = self.params or {}
		for i,k in pairs(v.params) do
			p[i] = k
		end
		self.matches[k].params = p
	end
	-- Loop over files, run command on matched
	for _, file in pairs(files)do
		statuses[file] = {}
		for pattern, s in pairs(self.matches) do
			if file:match(pattern) then 
				local status, msg = self:run_command(file,s)
				msg = msg or "No message given"
				table.insert(statuses[file],status)
				if status == false then
					print(msg)
					break
				end
			end
		end
	end
	return statuses
end

Make.run = function(self) 
	local return_codes = {}
  local params = self.params or {}
	for _,v in ipairs(self.build_seq) do
		--print("sekvence: "..v.name)
		for p,n in pairs(v.params) do params[p] = n end
		--for c,_ in pairs(params) do print("build param: "..c) end
		if type(v.command)=="function" then 
			table.insert(return_codes,{name=v.name,status = v.command(params)})
		elseif type(v.command) =="string" then
			local command = v.command % params
			print("Make4ht: " .. command)
			local status = os.execute(command)
			table.insert(return_codes,{name=v.name,status=status})
		else
			print("Unknown command type, must be string or function - " ..v.name..": "..type(v.command))
		end
	end
	local lgfile = params.input and params.input .. ".lg" or nil 
	if lgfile then
   	local lg = mkutils.parse_lg(lgfile)
		-- First convert images from lg files
		self:image_convert(lg["images"])
		-- Then run file matchers on lg files and converted images
		local files = lg["files"]
		for _,v in pairs(lg["images"]) do table.insert(files,v) end
		self:file_matches(files)
	else
		print("No lg file. tex4ht run failed?")
	end
	return return_codes
end

--[[Make:add("hello", "hello ${world}", {world = "world"})
Make:add("ajaj", "ajaj")
Make:hello()
Make:hello{world="světe"}
Make:hello()
Make:run()
--]]
