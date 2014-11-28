-- make4ht-cleanspan4ht.lua 
-- fixes spurious <span> elements in tex4ht output


function filter(input)
	local parse_args = function(s)
		local at = {}
		s:gsub("(%w+)%s*=%s*\"([^\"]-)\"", function(k,w)
			at[k]=w
		end)
		return at
	end
	-- local pattern = "(<?/?[%w]*>?)<span[%s]*class=\"([^\"]+)\"[%s]*>"
  local pattern = "(<?/?[%w]*>?)([%s]*)<span[%s]*([^>]-)>"
	local last_class = ""
	local depth = 0
	return  input:gsub(pattern, function(tag,space, args)
		local attr = parse_args(args) or {}
		local class = attr["class"] or ""
		if tag == "</span>" then
			if class == last_class and class~= ""  then 
				last_class = class
				return space .. ""
			end
		elseif tag == "" then
			class=""
		end
		last_class = class
		return tag ..space .. '<span '..args ..'>'
	end)
end

return filter
