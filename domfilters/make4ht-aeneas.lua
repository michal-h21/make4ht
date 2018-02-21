-- DOM filter for Aeneas, tool for automatical text and audio synchronization
-- https://github.com/readbeyond/aeneas
-- It adds elements with id attributes for text chunks, in sentence length.
--
--
local cssquery = require "luaxml-cssquery"

-- Table of CSS selectors to be skipped.
local skip_elements = {"head", "math", "svg"}

-- The id attribute format is configurable
-- Aeneas must be told to search for the ID pattern using is_text_unparsed_id_regex 
-- option in Aneas configuration file
local id_prefix = "ast"

-- convert table with selectors to a query list
local function prepare_selectors(skips)
  local css = cssquery()
  for _, selector in ipairs(skips) do
    css:add_selector(selector)
  end
  return css
end

local function make_span(id,parent, text)
  local newobj = parent:create_element("span", {id=id, class=id})
  newobj.processed = true
  local text_node = newobj:create_text_node(text)
  newobj:add_child_node(text_node)
  return newobj
end

local function make_id(lastid, id_prefix)
  local id = id_prefix .. lastid
  lastid = lastid + 1
  return id, lastid
end

local function make_ids(parent, text, lastid, id_prefix)
  local t = {}
  for chunk, punct in text:gmatch("([^%.^%?^!]*)([%.%?!]?)") do
    id, lastid = make_id(lastid, id_prefix)
    print(id, chunk, punct)
    table.insert(t, make_span(id, parent, chunk .. punct))
  end
  return t, lastid
end

-- test if the DOM element is in list of skipped CSS selectors
local function is_skipped(el, css)
  local matched = css:match_querylist(el)
  return #matched > 0
end


local function aeneas(dom, par)
  local par = par or {}
  local id = 1
  local options = get_filter_settings "aeneas"
  local skip_elements = options.skip_elements or par.skip_elements or skip_elements
  local id_prefix = options.id_prefix or par.id_prefix or id_prefix
  local skip_object = prepare_selectors(skip_elements)
  local body = dom:query_selector("body")[1]
  if not body then return dom end
  body:traverse_elements(function(el)
    -- skip disabled elements
    if(is_skipped(el, skip_object)) then return false end
    -- skip already processed elements 
    if el.processed then return false end
    local newchildren = {}
    if #el:get_children() == 1 and el._children[1]:is_text() and not el:get_attribute("id") then
      local idtitle
      idtitle, id = make_id(id, id_prefix)
      el:set_attribute("id", idtitle)
      return el
    end
    for _, child in ipairs(el:get_children()) do
      if child:is_text() and child._text:match("%a+") then
        local newnodes
        newnodes, id = make_ids(child, child._text, id, id_prefix)
        for _, node in ipairs(newnodes) do
          table.insert(newchildren, node or {})
        end
      else
        table.insert(newchildren, child or {})
      end
    end
    for k,v in ipairs(newchildren) do
      print(k, v:get_node_type(),v._name)
    end
    if #newchildren > 0 then
      el._children = {} -- newchildren
      -- local newel = el:copy_node()
      -- newel._children = {}
      for _, c in ipairs(newchildren) do
        el:add_child_node(c)
      end
      -- el:replace_node(newel)
    end
  end)
  print "*************************"
  return dom
end

return aeneas
