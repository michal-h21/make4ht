local log = logging.new("joincharacters")

local charclasses = {
  span=true,
  mn = true,
  mi = true
}

local function update_mathvariant(el, next_el)
  local set_mathvariant = function(curr)
    -- when we join several <mi> elements, they will be rendered incorrectly
    -- we must set the mathvariant attribute
    local parent = curr:get_parent()
    -- set mathvariant only if it haven't been set by the parent element
    if not parent:get_attribute("mathvariant") then
      curr._attr = curr._attr or {}
      local mathvariant = curr:get_attribute("mathvariant") or "italic"
      curr:set_attribute("mathvariant", mathvariant)
    end
  end
  if el:get_attribute("mathvariant") == next_el:get_attribute("mathvariant") then
    set_mathvariant(el)
    set_mathvariant(next_el)
  end
end

local table_count = function(tbl)
  local i = 0
  for k,v in pairs(tbl) do i = i + 1 end
  return i
end


local has_matching_attributes = function (el, next_el)
  local el_attr = el._attr or {}
  local next_attr = next_el._attr or {}
  -- if the number of attributes doesn't match, elements don't match
  if table_count(next_attr) ~= table_count(el_attr) then return false end
  for k, v in pairs(el_attr) do
    -- if any attribute doesn't match, elements don't match
    if v~=next_attr[k] then return false end
  end
  -- fix <mi> elements mathvariant attributes
  if el:get_element_name() == "mi" then 
    update_mathvariant(el, next_el) 
  end
  return true
end


local function join_characters(obj,par)
  -- join adjanced span and similar elements inserted by 
  -- tex4ht to just one object.
  local par = par or {}
  local options = get_filter_settings "joincharacters"
  local charclasses = options.charclasses or par.charclasses or charclasses


  obj:traverse_elements(function(el)
    local get_name = function(curr) 
      return string.lower(curr:get_element_name())
    end
    local get_class = function(next_el)
      return next_el:get_attribute("class") or next_el:get_attribute("mathvariant")
    end
    local is_span = function(next_el)
      return charclasses[get_name(next_el)]
    end

    local function get_next(curr, class)
      local next_el = curr:get_next_node()
      if next_el and next_el:is_element() and is_span(next_el) then
        return next_el
        -- if the next node is space followed by a matching element, we should add this space
      elseif next_el and next_el:is_text() and get_next(next_el, class) then
        local text = next_el._text 
        -- match only text containing just whitespace
        if text:match("^%s+$") then return next_el end
      end
    end
    -- loop over all elements and test if the current element is in a list of
    -- processed elements (charclasses)
    if is_span(el) then
      local next_el = get_next(el)
      -- loop over the following elements and test whether they are of the same type
      -- as the current one
      while  next_el do
        -- save the next element because we will remove it later
        local real_next = get_next(next_el)
        if get_name(el) == get_name(next_el) and has_matching_attributes(el,next_el) and not el:get_attribute("id") then
          -- it the following element match, copy it's children to the current element
          for _, child in ipairs(next_el:get_children()) do
            el:add_child_node(child)
          end
          -- remove the next element
          next_el:remove_node()
          -- add the whitespace
        elseif next_el:is_text() then
          local s = next_el._text
          -- we must create a new node
          el:add_child_node(el:create_text_node(s))
          next_el:remove_node()
          real_next = nil
        else
          real_next = nil
        end
        -- use the saved element as a next object
        next_el = real_next
      end
    end

  end)
  -- join text nodes in an element into one
  obj:traverse_elements(function(el)
    -- save the text
    local t = {}
    local children = el:get_children()
    for _, x in ipairs(children) do
      if x:is_text() then
        t[#t+1] = x._text
      else
        return nil
      end
    end
    el._text = table.concat(t)
    return el
  end)
  return obj
end

return join_characters
