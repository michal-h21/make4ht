-- cleanspan4ht.lua 
-- fixes spurious <span> elements in tex4ht output
-- usage: texlua cleanspan4ht filename
-- file `filename` is modified, fixed version is writed back

-- local filename = arg[1]

function filter(input)
	local pattern = "(<?/?[%w]*>?)<span[%s]*class=\"([^\"]+)\"[%s]*>"
	local last_class = ""
	return  input:gsub(pattern, function(tag, class) 
		if tag == "</span>" then
			if class == last_class then 
				last_class = class
				return ""
			end
		end
		last_class = class
		return tag .. '<span class="'..class..'">'
	end)
end

return filter
