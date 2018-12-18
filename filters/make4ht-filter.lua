local filter_lib = require "make4ht-filterlib"

local function load_filter(filtername)
	return require("filters.make4ht-"..filtername)
end

function filter(filters)
  local sequence = filter_lib.load_filters(filters, load_filter)
	return function(filename, parameters)
		if not filename then return false, "filters: no filename" end
    local input = filter_lib.load_input_file(filename)
    if not input  then return nil, "Cannot load the input file" end
		for _,f in pairs(sequence) do
			input = f(input,parameters)
		end
    filter_lib.save_input_file(filename, input)
	end
end
return filter
