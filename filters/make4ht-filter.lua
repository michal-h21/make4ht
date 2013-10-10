local filters = {}

local function load_filter(filtername)
	return require("filters.make4ht-"..filtername)
end

function filter(filters)
	local sequence = {}
	if type(filters) == "string" then
		table.insert(sequence,load_filter(filters))
	elseif type(filters) == "table" then
		for _,n in pairs(filters) do
			if type(n) == "string" then
				table.insert(sequence,load_filter(n))
			elseif type(n) == "function" then
				table.insert(sequence, n)
			end
		end
	elseif type(filters) == "function" then
		table.insert(sequence, filters)
	else
		return false, "Argument to filter must be either\ntable with filter names, or single filter name"
	end
	return function(filename)
		if not filename then return false, "filters: no filename" end
		local input = nil

		if filename then
			local file = io.open(filename,"r")
			input = file:read("*all")
			file:close()
		end
		for _,f in pairs(sequence) do
			input = f(input)
		end
		local file = io.open(filename,"w")
		file:write(input)
		file:close()
	end
end
return filter
