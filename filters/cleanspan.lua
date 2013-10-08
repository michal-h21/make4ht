-- cleanspan4ht.lua 
-- fixes spurious <span> elements in tex4ht output
-- usage: texlua cleanspan4ht filename
-- file `filename` is modified, fixed version is writed back

-- local filename = arg[1]

function filter(filename)
	if not filename then return false, "cleanspan: no filename" end
	local input = nil

	if filename then
		local file = io.open(filename,"r")
		input = file:read("*all")
		file:close()
	end

	--[[if not input then
	input = io.read("*all")
	end--]]

	-- this pattern looks for <span class="classname"> elements. 
	-- preceding content is also captured
	local pattern = "(<?/?[%w]*>?)<span[%s]*class=\"([^\"]+)\"[%s]*>"
	local last_class = ""

	-- this function looks at captured content, if previous content was 
	-- span element with same class as current element, all content is removed 
	local result = input:gsub(pattern, function(tag, class) 
		if tag == "</span>" then
			if class == last_class then 
				last_class = class
				return ""
			end
		end
		last_class = class
		return tag .. '<span class="'..class..'">'
	end)
	-- print(result)
	--
	print("cleanspan: "..filename)
	local file = io.open(filename,"w")
	file:write(result)
	file:close()
end

return filter
