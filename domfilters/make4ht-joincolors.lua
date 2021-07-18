local cssfiles = {}
local log = logging.new "joincolors"


-- keep mapping between span ids and colors
local colors = {}

local function extract_colors(csscontent)
  local used_colors = {}
  -- delete the color ids and save the used colors
  csscontent = csscontent:gsub("[%a]*%#(textcolor.-)%s*{%s*color%s*%:%s*(.-)%s*%}%s", function(id, color)
    -- convert rgb() function to hex value and generate the span name
    local converted = "textcolor-" .. color:gsub("rgb%((.-),(.-),(.-)%)", function(r,g,b)
      return string.format("%02x%02x%02x", tonumber(r), tonumber(g), tonumber(b))
    end)
    -- remove the # characters from the converted color name
    converted = converted:gsub("%#", "")
    -- save the id and used color
    colors[id] = converted
    used_colors[converted] = color
    return ""
  end)
  -- add the used colors to css
  local t = {}
  for class, color in pairs(used_colors) do
    t[#t+1] = string.format(".%s{color:%s;}", class, color)
  end
  table.sort(t)
  return csscontent .. table.concat(t, "\n")
end

local function process_css(cssfile)
  local f = io.open(cssfile,"r")
  if not f then return nil, "Cannot open the CSS file: ".. cssfile end
  local content = f:read("*all")
  f:close()
  -- delete color ids and replace them with joined spans
  local newcontent = extract_colors(content)
  -- save the updated css file
  local f=io.open(cssfile, "w")
  f:write(newcontent)
  f:close()
end


local function process_css_files(dom)
  for _, el in ipairs(dom:query_selector("link")) do
    local href = el:get_attribute("href") or ""
    if not cssfiles[href] and href:match("css$") then
      log:debug("Load CSS file ", href)
      cssfiles[href] = true
      process_css(href)
    end
  end

end

local function join_colors(dom)
  -- find css files in the current HTML file and join the colors
  process_css_files(dom)
  for _, span in ipairs(dom:query_selector("span")) do
    local id = span:get_attribute("id")
    if id then
      -- test if the id is in the saved colors
      local class = colors[id]
      if class then
        -- remove the id
        span:set_attribute("id", nil)
        span:set_attribute("class", class)
      end
    end
  end

  return dom
end

return join_colors
