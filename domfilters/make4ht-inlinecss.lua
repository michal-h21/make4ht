local cssquery  = require "luaxml-cssquery"

local log = logging.new("inlinecss")

local cssrules = {}
local cssobj   = cssquery()

local function parse_rule(line)
  -- parse CSS selector and attributes
  -- they are always on one line in the CSS file produced by TeX4ht
  local selector, values = line:match("%s*(.-)%s*(%b{})")
  if values then
    values = values:sub(2,-2)
  end
  return selector, values
end

local function join_values(old, new)
  -- correctly joins two attribute lists, depending on the ending
  local separator = ";"
  if not old then return new end
  -- if old already ends with ;, then don't use semicolon as a separator
  if old:match(";%s*$") then separator = "" end
  return old .. separator .. new
end

local function parse_css(filename)
  local css_file = io.open(filename, "r")
  if not css_file then return nil, "cannot load css file: " .. (filename or "") end
  local newlines = {}
  for line in css_file:lines() do
    -- match lines that contain # or =, as these can be id or attribute selectors
    if line:match("[%#%=].-{") then
      -- update attributes for the current selector
      local selector, value = parse_rule(line)
      local oldvalue = cssrules[selector] 
      cssrules[selector] = join_values(oldvalue, value)
    else
      newlines[#newlines+1] = line
    end
  end
  -- we need to add css rules
  for selector, value in pairs(cssrules) do
    cssobj:add_selector(selector, function(dom) end, {value=value})
  end
  css_file:close()
  -- write new version of the CSS file, without rules for ids and attributes
  local css_file = io.open(filename, "w")
  css_file:write(table.concat(newlines, "\n"))
  css_file:close()
  return true
end

local processed = false

-- process the HTML file and insert inline CSS for id and attribute selectors
return function(dom, par)
  if not processed then 
    -- process the CSS file before everything else, but only once
    processed = true
    local css_file = mkutils.file_in_builddir(par.input .. ".css", par)
    local status, msg = parse_css(css_file)
    if not status then log:warning(msg) end
  end
  -- loop over all elements in the current page
  dom:traverse_elements(function(curr)
    -- use CSS object to match if the current element
    -- is matched by id attribute selector
    local matched = cssobj:match_querylist(curr)
    if #matched > 0 then
      -- join possible already existing style attribute with values from the CSS file
      local values = curr:get_attribute("style")
      -- join values of all matched rules
      for _,rule in ipairs(matched) do
        values = join_values(values, rule.params.value)
      end
      curr:set_attribute("style", values)
    end

  end)
  return dom
end

