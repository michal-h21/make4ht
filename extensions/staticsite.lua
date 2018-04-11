local M = {}
local filter = require "make4ht-filter"
local domfilter = require "make4ht-domfilter"
local domobj = require "luaxml-domobject"
local mkutils = require "mkutils"

local function get_slug(settings)
  local published_name = mkutils.remove_extension(settings.tex_file) .. ".published"

  local slug = os.date("%Y-%m-%d-" .. settings.input)
  if mkutils.file_exists(published_name) then
    local f = io.open(published_name, "r")
    slug = f:read("*line")
    print("Already pubslished", slug)
    -- settings.input = published_filename
    f:close()
  else
    -- escape 
    -- slug must contain the unescaped input name
    local f = io.open(published_name, "w") 
    f:write(slug)
    f:close()
    -- make the output file name in the format YYYY-MM-DD-old-filename.html
  end
  return slug
end

function M.test(format)
  Make.input = "hello"
  local settings = Make.params
  return true
end

-- Make:enable_extension ( "tidy" )
-- os.exit()
-- Make:disable_extension ("common_domfilters")
-- table.insert(settings.extensions,{type="-", name= "common_domfilters"})
-- table.insert(settings.extensions,{type="+", name= "grrr"})
local function make_yaml(tbl, level)
  local t = {}
  local level = level or 0
  local indent = string.rep("  ", level)
  -- indentation for multilen strings
  local str_indent = string.rep("  ", level + 1)
  for k,v in pairs(tbl) do
    if type(v)=="string" then
      -- detect multiline strings
      if v:match("\n") then
        table.insert(t, string.format(indent .. "%s: |", k))
        v = str_indent .. (v:gsub("\n", "\n".. str_indent))
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
            table.insert(t, indent .. "-")
            table.insert(t, make_yaml(y, level + 1))
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

local function get_header(tbl)
  local yaml = make_yaml(tbl)
  return "---\n".. yaml.. "\n---\n"
end


-- if mode=="publish" then
function M.modify_build(make)
  local process = filter {
    function(s,par)
      print(os.getenv "blog_home")
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
        print(meta:serialize())
        table.insert(metas, {charset= meta:get_attribute("charset"), content = meta:get_attribute("content"), property = meta:get_attribute("property"), name = meta:get_attribute("name")})
      end
      properties.meta = metas


      local body = dom:query_selector("body")[1]
      print(get_header(properties))
      -- return s
      return get_header(properties) .. body:serialize():gsub("<body.->", ""):gsub("</body>", "")
    end
  }
  local settings = make.params
  local slug = get_slug(settings)
  for _, cmd in ipairs(make.build_seq) do
    cmd.params.input = slug
    if cmd.name == "htlatex" then

    end
  end

  -- settings.input = slug
  -- settings.extensions = mkutils.add_extensions("-common_domfilters+tidy", settings.extensions)
  -- settings.extensions = mkutils.add_extensions("-common_domfilters+tidy", settings.extensions)
  local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
  local mainfile = string.gsub(slug, quotepattern, "%%%1")
  -- make:htlatex {}
  -- match only the main input file
  make:match("tmp$", function(a) 
    print "pubslih jede"
    print("input",settings.input)
    for k,v in pairs(settings.extensions) do
      print("extension", k)
      for x,y in pairs(v) do print(x,y) end
    end
    return a
  end)

  make:match(mainfile .. ".html", process)
  return make
end

return M
