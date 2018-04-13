local M = {}

-- the filter module  must implement the load_filter function
function M.load_filters(filters, load_filter)
	local sequence = {}
	if type(filters) == "string" then
		table.insert(sequence,load_filter(filters))
	elseif type(filters) == "table" then
		for _,n in ipairs(filters) do
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
  return sequence
end

function M.load_input_file(filename)
  if not filename then return false, "filters: no filename" end
  local input = nil

  if filename then
    local file = io.open(filename,"r")
    input = file:read("*all")
    file:close()
  end
  return input
end

function M.save_input_file(filename, input)
  local file = io.open(filename,"w")
  file:write(input)
  file:close()
end

return M
