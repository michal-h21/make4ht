local domobj = require "luaxml-domobject"
local log = logging.new("staticsite")
-- save the header settings in YAML format
local function make_yaml(tbl, level)
  local t = {}
  local level = level or 0
  local indent = string.rep("  ", level)
  -- indentation for multilen strings
  local str_indent = string.rep("  ", level + 1)
  local sorted = {}
  for k, _ in pairs(tbl) do
    sorted[#sorted+1] = k
  end
  table.sort(sorted)
  for _,k in ipairs(sorted) do
    local v = tbl[k]
    if type(v)=="string" then
      -- detect multiline strings
      if v:match("\n") then
        table.insert(t, string.format(indent .. "%s: |", k))
        table.insert(t, str_indent .. (v:gsub("\n", "\n".. str_indent)))
      else
        v = v:gsub("'", "''")
        table.insert(t, string.format(indent .. "%s: '%s'", k,v))
      end
    elseif type(v) == "table" then
      table.insert(t,string.format(indent .. "%s:", k))
      -- we need to differently process array and hash table
      -- we don't support mixing types
      if #v > 0 then
        for x,y in ipairs(v) do
          if type(y) == "string" then
            -- each string can be printed on it's own line
            table.insert(t, indent .. string.format("- '%s'", y))
          else
            -- subtables need to be indented
            -- table.insert(t, indent .. "-")
            local subtable = make_yaml(y, level + 1)
            -- we must insert dash at a correct place
            local insert_dash = subtable:gsub("^(%s*)%s%s", "%1- ")
            table.insert(t, insert_dash)
          end
        end
      else
        -- print indented table
        table.insert(t, make_yaml(v,level + 1))
      end
    else
      -- convert numbers and other values to string
      table.insert(t, string.format(indent .. "%s: %s", k,tostring(v)))
    end
    
  end
  return table.concat(t,  "\n")
end

local function update_properties(properties, dom)
  -- enable properties update from the config or build file
  local settings = get_filter_settings "staticsite" or {}
  local header = settings.header or {}
  -- set non-function properties first
  for field, rule in pairs(header) do
    if type(rule) ~="function" then
      properties[field] = rule
    end
  end
  -- then execute functions. it ensures that all propeties set in header are available
  for field, rule in pairs(header) do
    -- it is possible to pass function as a rule, it will be executed with properties as a parameter
    if type(rule) == "function" then
      properties[field] = rule(properties, dom)
    end
  end
  return properties
end

local function get_header(tbl)
  local yaml = make_yaml(tbl)
  return "---\n".. yaml.. "\n---\n"
end

return function(s,par)
  local dom = domobj.parse(s)
  local properties = {}
  local head = dom:query_selector("head")[1]
  properties.title = head:query_selector("title")[1]:get_text()
  local styles = {}
  for _, link in ipairs(head:query_selector("link")) do
    local typ = link:get_attribute("type")
    if typ == "text/css" then 
      table.insert(styles, link:get_attribute("href"))
    end
  end
  properties.styles = styles
  local metas = {}
  for _, meta in ipairs(head:query_selector("meta")) do
    log:debug("parsed meta: " .. meta:serialize())
    table.insert(metas, {charset= meta:get_attribute("charset"), content = meta:get_attribute("content"), property = meta:get_attribute("property"), name = meta:get_attribute("name")})
  end
  properties.meta = metas
  properties = update_properties(properties, dom)


  local body = dom:query_selector("body")[1]
  log:debug(get_header(properties))
  -- return s
  return get_header(properties) .. body:serialize():gsub("<body.->", ""):gsub("</body>", "")
end
