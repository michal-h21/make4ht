-- Fix bad entities
-- Sometimes, tex4ht produce named xml entities, which are prohobited in epub
-- &nbsp;, for example
function filter(s)
	local replaces = {
	nbsp = "#160"
	}
	return s:gsub("&(%w+);",function(x) 
		local m = replaces[x] or x
		return "&"..m..";"
	end)
end

return filter
