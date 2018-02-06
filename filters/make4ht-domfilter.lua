local filter_lib = require "make4ht-filterlib"
local mkutils    = require "mkutils"

local function load_filter(filtername)
	return require("filters.make4ht-"..filtername)
end

local function filter(filters, name)
  local sequence = filter_lib.load_filters(filters, load_filter)

	return function(filename, parameters)
    local input = filter_lib.load_input_file(filename)
		for _,f in pairs(sequence) do
			input = f(input,parameters)
		end
    filter_lib.save_input_file(filename, input)
	end
end
return filter
