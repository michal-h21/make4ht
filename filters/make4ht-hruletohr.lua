-- hruletohr
-- \hrule primitive is impossible to redefine catching all possible arguments
-- with tex4ht, it is converted as series of underscores 
-- it seems that these underscores are always part of previous paragraph
-- this assumption may be wrong, needs more real world testing

local hruletohr = function(s)
	return s:gsub("___+(.-)</p>","%1</p>\n<hr class=\"hrule\" />")
end

return hruletohr
