-- we need to set dimensions for SVG images produced by \Picture commands
local log = logging.new "odtsvg"
local function get_svg_dimensions(filename) 
  local width, height
  log:debug("file exists", filename, mkutils.file_exists(filename))
  if mkutils.file_exists(filename) then 
    for line in io.lines(filename) do
      width = line:match("width%s*=%s*[\"'](.-)[\"']") or width
      height = line:match("height%s*=%s*[\"'](.-)[\"']") or height
      -- stop parsing once we get both width and height
      if width and height then break end
    end
  end
  return width, height
end


-- process 
return function(dom)
  for _, pic in ipairs(dom:query_selector("draw|image")) do
    local imagename = pic:get_attribute("xlink:href")
    -- update SVG images dimensions
    log:debug("image", imagename)
    local parent = pic:get_parent()
    local width =  parent:get_attribute("svg:width")
    local height = parent:get_attribute("svg:height")
    -- if width == "0.0pt" then width = nil end
    -- if height == "0.0pt" then height = nil end
    if not width or not height then
      if imagename:match("svg$") then
        width, height = get_svg_dimensions(imagename) --  or width, height
      elseif imagename:match("png$") or imagename:match("jpe?g$") then
      end
    end
    log:debug("dimensions", width, height)
    parent:set_attribute("svg:width", width)
    parent:set_attribute("svg:height", height)
    -- if 
  end
  return dom
end

