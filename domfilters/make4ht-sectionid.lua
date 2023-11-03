local mkutils   = require "mkutils"
local log = logging.new("tocid")
-- Unicode data distributed with ConTeXt
-- defines "characters" table
if not mkutils.isModuleAvailable("char-def") then
  log:warning("char-def module not found")
  log:warning("cannot fix section id's")
  return function(dom) return dom end
end
require "char-def"
local chardata = characters.data or {}


local toc = nil

local function is_letter(info)
  -- test if character is letter
  local category = info.category or ""
  return category:match("^l") 
end

local function is_space(info)
  local category = info.category or ""
  return category == "zs"
end

local uchar = utf8.char
local function normalize_letter(char, result)
  local info = chardata[char] or {}
  -- first get lower case of the letter
  local lowercase = info.lccode or char
  -- remove accents. the base letter is in the shcode field
  local lowerinfo = chardata[lowercase] or {}
  -- when no shcode, use the current lowercase char
  local shcode = lowerinfo.shcode or lowercase
  -- shcode can be table if it contains multiple characters
  -- normaliz it to a table, so we can add all letters to 
  -- the resulting string
  if type(shcode) ~= "table" then shcode = {shcode} end
  for _, x in ipairs(shcode) do
    result[#result+1] = uchar(x)
  end
end

local escape_name = function(name)
  local result = {}
  -- remove LaTeX commands
  name = name:gsub("\\[%a]+", "")
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  for _,char in utf8.codes(name) do
    local info = chardata[char] or {}
    if is_space(info) then
      result[#result+1] = " "
    elseif is_letter(info) then
      normalize_letter(char, result)
    end
  end
  --- convert table with normalized characters to string
  local name = table.concat(result)
  -- remove spaces
  name = name:gsub("%s+", "-")
  name = name:gsub("^%-", "")
  return name
end

local function parse_toc_line(line)
  -- the section ids and titles are saved in the following format:
  -- \csname a:TocLink\endcsname{1}{x1-20001}{QQ2-1-2}{Nazdar světe}
  -- ............................... id ................. title ...
  local id, name = line:match("a:TocLink.-{.-}{(.-)}{.-}(%b{})")
  if id then
    return id, escape_name(name)
  end
end

local used = {}

local function parse_toc(filename)
  local toc = {}
  if not mkutils.file_exists(filename) then return nil, "Cannot open TOC file "  .. filename end
  for line in io.lines(filename) do
    local id, name = parse_toc_line(line)
    -- if section name doesn't contain any text, it would lead to id which contains only number
    -- this is invalid in HTML
    if name == "" then name = "_" end
    local orig_name = name
    -- not all lines in the .4tc file contains TOC entries
    if id then
      -- test if the same name was used already. user should be notified
      if used[name] then
        -- update 
        name = name .. used[name]
        log:debug("Duplicate id found: ".. orig_name .. ". New id: " .. name)
      end
      used[orig_name] = (used[orig_name] or 0) + 1
      toc[id] = name
    end
  end
  return toc
end

-- we don't want to change the original id, as there may be links to it from the outside
-- so we will set it to the parent element (which should be h[1-6])
local function set_id(el, id)
  local section = el:get_parent()
  local section_id = section:get_attribute("id")
  if section_id and section_id~=id then -- if it already has id, we don't override it, but create dummy child instead
    local new = section:create_element("span", {id=id})
    section:add_child_node(new,1)
  else
    section:set_attribute("id", id)
  end

end

    
-- we want to remove <a id="xxx"> elements from some elements, most notably <figure>
local elements_to_remove = {
  figure = true,
  figcaption
}

local function remove_a(el, parent, id)
  parent:set_attribute("id", id)
  el:remove_node()
end

return  function(dom, par)
    local msg
    toc, msg = toc or parse_toc(mkutils.file_in_builddir(par.input .. ".4tc", par))
    msg = msg or "Cannot load TOC"
    -- don't do anyting if toc cannot be found
    if not toc then 
      log:warning(msg) 
      return dom
    end
    -- if user selects the "notoc" option on the command line, we 
    -- will not update href links
    local notoc = false
    if par["tex4ht_sty_par"]:match("notoc") then notoc = true end
    -- the HTML file can already contain ID that we want to assign
    -- we will not set duplicate id from TOC in that case
    local toc_ids = {}
    for _, el in ipairs(dom:query_selector("[id]")) do
      local id = el:get_attribute("id")
      toc_ids[id] = true
    end
    -- process all elements with id atribute or <a href>
    for _, el in ipairs(dom:query_selector "[id],a[href]") do
      local id, href = el:get_attribute("id"), el:get_attribute("href") 
      if id then
        local name = toc[id]
        local parent = el:get_parent()
        -- remove unnecessary <a> elements if the parent doesn't have id yet
        if elements_to_remove[parent:get_element_name()] 
          and not parent:get_attribute("id") 
          and el:get_element_name() == "a"
        then
          remove_a(el, parent, id)
          set_id(el, name)
        -- replace id with new section id
        elseif name and not toc_ids[name] then
          set_id(el, name)
        else
          if name then
            log:debug("Document already contains id: " .. name)
          end
        end
      end
      if href and notoc == false then
        -- replace links to sections with new id
        local base, anchor = href:match("^(.*)%#(.+)")
        local name = toc[anchor]
        if name then
          el:set_attribute("href", base .. "#" .. name)
        end
      end
    end
    return dom
  end


