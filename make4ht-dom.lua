--- DOM module for LuaXML
-- @module make4ht-dom
local dom = {}
local xml = require("luaxml-mod-xml")
local handler = require("luaxml-mod-handler")
local query = require("make4ht-parse-query")


local void = {area = true, base = true, br = true, col = true, hr = true, img = true, input = true, link = true, meta = true, param = true}

local actions = {
  TEXT = {text = "%s"},
  COMMENT = {start = "<!-- ", text = "%s", stop = " -->"},
  ELEMENT = {start = "<%s%s>", stop = "</%s>", void = "<%s%s />"},
  DECL = {start = "<?%s %s?>"},
  DTD = {start = "<!DOCTYPE ", text = "%s" , stop=">"}
}

--- It serializes the DOM object back to XML 
-- @function serialize_dom
-- @param parser DOM object
-- @param current 
-- @param level
-- @param output
-- @return table
function serialize_dom(parser, current,level, output)
  local output = output or {}
  local function get_action(typ, action)
    local ac = actions[typ] or {}
    local format = ac[action] or ""
    return format
  end
  local function insert(format, ...)
    table.insert(output, string.format(format, ...))
  end
  local function prepare_attributes(attr)
    local t = {}
    local attr = attr or {}
    for k, v in pairs(attr) do
      t[#t+1] = string.format("%s='%s'", k, v)
    end
    if #t == 0 then return "" end
    -- add space before attributes
    return " " .. table.concat(t, " ")
  end
  local function start(typ, el, attr)
    local format = get_action(typ, "start")
    insert(format, el, prepare_attributes(attr))
  end
  local function text(typ, text)
    local format = get_action(typ, "text")
    insert(format, text)
  end
  local function stop(typ, el)
    local format = get_action(typ, "stop")
    insert(format,el)
  end
  local level = level or 0
  local spaces = string.rep(" ",level)
  local root= current or parser._handler.root
  local name = root._name or "unnamed"
  local xtype = root._type or "untyped"
  local text_content = root._text or ""
  local attributes = root._attr or {}
  -- if xtype == "TEXT" then
  --   print(spaces .."TEXT : " .. root._text)
  -- elseif xtype == "COMMENT" then
  --   print(spaces .. "Comment : ".. root._text)
  -- else
  --   print(spaces .. xtype .. " : " .. name)
  -- end
  -- for k, v in pairs(attributes) do
  --   print(spaces .. " ".. k.."="..v)
  -- end
  if xtype == "DTD" then
    text_content = string.format('%s %s "%s" "%s"', name, attributes["_type"],  attributes._name, attributes._uri )
    attributes = {}
  elseif xtype == "ELEMENT" and void[name] then
    local format = get_action(xtype, "void")
    insert(format, name, prepare_attributes(attributes))
    return output
  end

  start(xtype, name, attributes)
  text(xtype,text_content) 
  local children = root._children or {}
  for _, child in ipairs(children) do
    output = serialize_dom(parser,child, level + 1, output)
  end
  stop(xtype, name)
  return output
end

local parse = function(x)
  local domHandler = handler.domHandler()
  local Parser = xml.xmlParser(domHandler)
  -- preserve whitespace
  Parser.options.stripWS = nil
  Parser:parse(x)
  Parser.current = Parser._handler.root
  Parser.__index = Parser

  local function save_methods(element)
    setmetatable(element,Parser)
    local children = element._children or {}
    for _, x in ipairs(children) do
      save_methods(x)
    end
  end
  local parser = setmetatable({}, Parser)

  --- @class Parser
  function Parser.root_node(self)
    return self._handler.root
  end


  function Parser.get_element_type(self, el)
    local el = el or self
    return el._type
  end
  function Parser.is_element(self, el)
    local el = el or self
    return self:get_element_type(el) == "ELEMENT" 
  end

  function Parser.is_text(self, el)
    local el = el or self
    return self:get_element_type(el) == "TEXT"
  end

  local lower = string.lower

  function Parser.get_element_name(self, el)
    local el = el or self
    return el._name or "unnamed"
  end

  function Parser.get_attribute(self, name)
    local el = self
    if self:is_element(el) then
      local attr = el._attr or {}
      return attr[name]
    end
  end

  function Parser.set_attribute(self, name, value)
    local el = self
    if self:is_element(el) then
      el._attr[name] = value
      return true
    end
  end
  

  function Parser.serialize(self, current)
    local current = current
    -- if no current element is added and self is not plain parser object
    -- (_type is then nil), use the current object as serialized root
    if not current and self._type then
      current = self
    end
    return table.concat(serialize_dom(self, current))
  end

  function Parser.get_path(self,path, current)
    local function traverse_path(path_elements, current, t)
      local t = t or {}
      if #path_elements == 0 then 
        -- for _, x in ipairs(current._children or {}) do
          -- table.insert(t,x)
        -- end
        table.insert(t,current)
        return t
      end
      local current_path = table.remove(path_elements, 1)
      for _, x in ipairs(self:get_children(current)) do
        if self:is_element(x) then
          local name = string.lower(self:get_element_name(x))
          if name == current_path then
            t = traverse_path(path_elements, x, t)
          end
        end
      end
      return t
    end
    local current = current or self:root_node() -- self._handler.root
    local path_elements = {}
    local path = string.lower(path)
    for el in path:gmatch("([^%s]+)") do table.insert(path_elements, el) end
    return traverse_path(path_elements, current)
  end

  function Parser.calculate_specificity(self, query)
    local query = query or {}
    local specificity = 0
    for _, item in ipairs(query.query or {}) do
      for key, value in pairs(item) do
        if key == "id" then
          specificity = specificity + 100
        elseif key == "tag" then
          specificity = specificity + 1
        else
          specificity = specificity + 10
        end
      end
    end
    return specificity
  end

  function Parser.match_querylist(self, querylist)
    local matches = {}
    local querylist = querylist

    local function test_part(key, value, el)
      -- print("testing", key, value, el:get_element_name())
      if key == "tag" then 
        return el:get_element_name() == value
      elseif key == "id" then
        local id = el:get_attribute "id"
        return id and id == value
      elseif key == "class" then 
        local class = el:get_attribute "class"
        if not class then return false end
        local c = {}
        for part in class:gmatch "([^%s]+)" do
          c[part] = true
        end
        return c[value] == true
      end
      -- TODO: Add more cases
      -- just return true for not supported selectors
      return true
    end

    local function test_object(query, el)
      -- test one object in CSS selector
      local matched = {}
      for key, value in pairs(query) do
        matched[#matched+1] = test_part(key, value, el)
      end
      if #matched == 0 then return false end
      for k, v in ipairs(matched) do
        if v ~= true then return false end
      end
      return true
    end
        
    local function match_query(query, el)
      local query = query or {}
      local object = table.remove(query) -- get current object from the query stack
      if not object then return true end -- if the query stack is empty, then we can be sure that it matched previous items
      if not el:is_element() then return false end -- if there is object to test, but current node isn't element, test failed
      local result = test_object(object, el)
      if result then
        return match_query(query, el:get_parent())
      end
      return false
    end
    for _,element in ipairs(querylist) do
      local query =  {}
      for k,v in ipairs(element.query) do query[k] = v end
      if #query > 0 then -- don't try to match empty query
        local result = match_query(query, self)
        if result then matches[#matches+1] = element end
      end
    end
    return matches
  end

  function Parser.get_selector_path(self, selectorlist)
    local nodelist = {}
    self:traverse_elements(function(el)
      local matches = el:match_querylist(selectorlist)
      print("Matching", el:get_element_name(), #matches)
      if #matches > 0 then nodelist[#nodelist+1] = el
      end
    end)
    return nodelist
  end

  --- Parse CSS selector to match table
  function Parser.prepare_selector(self, selector)
    local querylist = {}
    local function parse_selector(item)
      local query = {}
      -- for i = #item, 1, -1 do
        -- local part = item[i]
      for _, part in ipairs(item) do
        local t = {}
        for _, atom in ipairs(part) do
          local key = atom[1]
          local value = atom[2]
          t[key] =  value
        end
        query[#query + 1] = t
      end
      return query
    end
    -- for item in selector:gmatch("([^%s]+)") do
    -- elements[#elements+1] = parse_selector(item)
    -- end
    local parts = query.parse_query(selector) or {}
    -- several selectors may be separated using ",", we must process them separately
    for _, part in ipairs(parts) do
      querylist[#querylist+1] = {query =  parse_selector(part)}
    end
    return querylist
  end

  function Parser.get_children(self, el)
    local el  = el or self
    local children = el._children or {}
    return children
  end

  function Parser.get_parent(self, el)
    local el = el or self
    return el._parent
  end

  function Parser.traverse_elements(self, fn, current)
    local current = current or self:root_node()
    local status = true
    if self:is_element(current) or self:get_element_type(current) == "ROOT"then
      local status = fn(current)
      -- don't traverse child nodes when the user function return false
      if status ~= false then
        for _, child in ipairs(self:get_children(current)) do
          self:traverse_elements(fn, child)
        end
      end
    end
  end

  function Parser.traverse_node_list(self, nodelist, fn)
    local nodelist = nodelist or {}
    for _, node in ipairs(nodelist) do
      for _, element in ipairs(node._children) do
        fn(element)
      end
    end
  end

  function Parser.replace_node(self,  new)
    local old = self
    local parent = self:get_parent(old)
    local id,msg = self:find_element_pos( old)
    if id then
      parent._children[id] = new
      return true
    end
    return false, msg
  end

  function Parser.add_child_node(self, child)
    local parent = self
    child._parent = parent
    table.insert(parent._children, child)
  end


  function Parser.copy_node(self, element)
    local element = element or self
    local t = {}
    for k, v in pairs(element) do
      if type(v) == "table" and k~="_parent" then
        t[k] = self:copy_node(v)
      else
        t[k] = v
      end
    end
    save_methods(t)
    return t
  end

  function Parser.create_element(self, name, attributes, parent)
    local parent = parent or self
    local new = {}
    new._type = "ELEMENT"
    new._name = name
    new._attr = attributes or {}
    new._children = {}
    new._parent = parent
    save_methods(new)
    return new
  end

  function Parser.remove_node(self, element)
    local element = element or self
    local parent = self:get_parent(element)
    local pos = self:find_element_pos(element)
    -- if pos then table.remove(parent._children, pos) end
    if pos then 
      -- table.remove(parent._children, pos) 
      parent._children[pos] = setmetatable({_type = "removed"}, Parser)
    end
  end

  function Parser.find_element_pos(self, el)
    local el = el or self
    local parent = self:get_parent(el)
    if not self:is_element(parent) and self:get_element_type(parent) ~= "ROOT" then return nil, "The parent isn't element" end
    for i, x in ipairs(parent._children) do
      if x == el then return i end
    end
    return false, "Cannot find element"
  end

  function Parser.get_siblibgs(self, el)
    local el = el or self
    local parent = el:get_parent()
    if parent:is_element() then
      return parent:get_children()
    end
  end

  function Parser.get_sibling_node(self, change)
    local el = self
    local pos = el:find_element_pos()
    local siblings = el:get_siblibgs()
    if pos and siblings then
      return siblings[pos + change]
    end
  end

  function Parser.get_next_node(self, el)
    local el = el or self
    return el:get_sibling_node(1)
  end

  function Parser.get_prev_node(self, el)
    local el = el or self
    return el:get_sibling_node(-1)
  end


  -- include the methods to all xml nodes
  save_methods(parser._handler.root)
  -- parser:
  return parser
end


local M = {}
M.parse = parse
M.serialize= serialize_dom
return M
