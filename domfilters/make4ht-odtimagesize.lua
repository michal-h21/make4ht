local log = logging.new "odtimagesize"
-- set correct dimensions to frames around images
return  function(dom)
  local frames  = dom:query_selector("draw|frame")
  for _, frame in ipairs(frames) do
    local images = frame:query_selector("draw|image")
    if #images > 0 then
      local image = images[1]
      local width = image:get_attribute("svg:width")
      local height = image:get_attribute("svg:height")
      if widht then frame:set_attribute("svg:width", width) end
      if height then frame:set_attribute("svg:height", height) end
      log:debug("image dimensions", width, height)
    end
  end
  return dom
end
