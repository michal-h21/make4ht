local filter_lib = require "make4ht-filterlib"
local dom    = require "luaxml-domobject"
local mkutils    = require "mkutils"

local function load_filter(filtername)
	return require("filters.make4ht-"..filtername)
end

local function filter(filters, name)
  local sequence = filter_lib.load_filters(filters, load_filter)

	return function(filename, parameters)
    local input = filter_lib.load_input_file(filename)
    if not input  then return nil, "Cannot load the input file" end
    local domobject = dom.parse(input)
		for _,f in pairs(sequence) do
			domobject = f(domobject,parameters)
		end
    local output = domobject:serialize()
    filter_lib.save_input_file(filename, output)
	end
end
return filter
