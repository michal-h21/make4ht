local filter_lib = require "make4ht-filterlib"
local dom    = require "luaxml-domobject"
local mkutils    = require "mkutils"

local function load_filter(filtername)
	return require("domfilters.make4ht-"..filtername)
end

local function filter(filters, name)
  -- because XML parsing to DOM is potentially expensive operation
  -- this filter will use cache for it's sequence
  -- all requests to the domfilter will add new filters to the
  -- one sequence, which will be executed on one DOM object.
  -- it is possible to request a different sequence using
  -- unique name parameter
  local name = name or "domfilter"
  local settings = mkutils.get_filter_settings(name) or {}
  local sequence = settings.sequence or {}
  local local_sequence = filter_lib.load_filters(filters, load_filter)
  for _, filter in ipairs(local_sequence) do
    table.insert(sequence, filter)
  end
  settings.sequence = sequence
  mkutils.filter_settings (name) (settings)

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
