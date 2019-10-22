local filter_lib = require "make4ht-filterlib"
local dom    = require "luaxml-domobject"
local mkutils    = require "mkutils"
local log = logging.new "domfilter"

local function load_filter(filtername)
	return require("domfilters.make4ht-"..filtername)
end

-- save processed names, in order to block multiple executions of the filter
-- sequence on a same file
local processed = {}

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
    -- load processed files for the current filter name
    local processed_files = processed[name] or {}
    -- don't process the file again
    if processed_files[filename] then
      return nil
    end
    local input = filter_lib.load_input_file(filename)
    if not input  then return nil, "Cannot load the input file" end
    -- we need to use pcall, because XML error would break the whole build process
    -- domobject will be error object if DOM parsing failed
    local status, domobject = pcall(function()
      return dom.parse(input)
    end)
    if not status then
      log:warning("DOM parsing of " .. filename .. " failed:")
      log:warning(domobject)
      return nil, "DOM parsing failed"
    end
		for _,f in pairs(sequence) do
			domobject = f(domobject,parameters)
		end
    local output = domobject:serialize()
    if output then
      filter_lib.save_input_file(filename, output)
    else
      log:warning("DOM filter failed on ".. filename)
    end
    -- mark the filename as processed
    processed_files[filename] = true
    processed[name] = processed_files
	end
end
return filter
