
local log = logging.new("svg-height")
-- Make:image("svg$", "dvisvgm -n -a -p ${page} -b preview -c 1.4,1.4 -s ${source} > ${output}")


local max = function(a,b)
  return a > b and a or b
end

local function get_height(svg)
  local height = svg:match("height='([0-9%.]+)pt'")
  return tonumber(height)
end

local function get_max_height(path,max_number)
  local coordinates = {}
  for number in path:gmatch("(%-?[0-9%.]+)") do
    table.insert(coordinates, tonumber(number))
  end
  for i = 2, #coordinates, 2 do
    max_number = max(max_number, coordinates[i])
  end
  return max_number
end

local function update_height(svg, height)
  return svg:gsub("height='.-pt'", "height='"..height .."pt'")
end

-- we need to fix the svg height
return function(svg)
  local max_height = 0
  local height = get_height(svg)
  for path in svg:gmatch("path d='([^']+)'") do
    -- find highest height in all paths in the svg file
    max_height = get_max_height(path, max_height)
  end
  -- update the height only if the max_height is larger than height set in the SVG file
  log:debug("max height and height", max_height, height)
  if max_height > height then
    svg = update_height(svg, max_height)
  end
  return svg
end

