local log = logging.new("joincharacters")

local charclasses = {
  span=true,
  mn = true,
}

local function update_mathvariant(curr)
  -- when we join several <mi> elements, they will be rendered incorrectly
  -- we must set the mathvariant attribute
  local parent = curr:get_parent()
  -- set mathvariant only if it haven't been set by the parent element
  if not parent:get_attribute("mathvariant") then
    -- curr._attr = curr._attr or {}
    local mathvariant = "italic"
    -- the joined elements don't have attributes
    curr._attr = curr._attr or {}
    curr:set_attribute("mathvariant", mathvariant)
  end
end

local table_count = function(tbl)
  local tbl = tbl or {}
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
  return true
end


local function join_characters(obj,par)
  -- join adjanced span and similar elements inserted by 
  -- tex4ht to just one object.
  local par = par or {}
  local options = get_filter_settings "joincharacters"
  local charclasses = options.charclasses or par.charclasses or charclasses

  local get_name = function(curr) 
    return string.lower(curr:get_element_name())
  end
  local get_class = function(next_el)
    return next_el:get_attribute("class") or next_el:get_attribute("mathvariant")
  end
  local is_span = function(next_el)
    return charclasses[get_name(next_el)]
  end
  local has_children = function(curr)
    -- don't process spans that have child elements
    local children = curr:get_children() or {}
    -- if there is more than one child, we can be sure that it has child elements
    if #children > 1 then 
      return true 
    elseif #children == 1 then
      -- test if the child is an element
      return children[1]:is_element()
    end
    return false
  end
  local join_elements = function(el, next_el)
    -- it the following element match, copy it's children to the current element
    for _, child in ipairs(next_el:get_children()) do
      el:add_child_node(child)
    end
    -- remove the next element
    next_el:remove_node()
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

  obj:traverse_elements(function(el)
    -- loop over all elements and test if the current element is in a list of
    -- processed elements (charclasses) and if it doesn't contain children
    if is_span(el) and not has_children(el) then
      local next_el = get_next(el)
      -- loop over the following elements and test whether they are of the same type
      -- as the current one
      while next_el do
        -- save the next element because we will remove it later
        local real_next = get_next(next_el)
        if get_name(el) == get_name(next_el) and has_matching_attributes(el,next_el) and not el:get_attribute("id") then
          join_elements(el, next_el)
          -- add the whitespace
        elseif next_el:is_text() then
          local s = next_el._text
          -- we must create a new node
          el:add_child_node(el:create_text_node(s))
          next_el:remove_node()
          -- real_next = nil
        else
          real_next = nil
        end
        -- use the saved element as a next object
        next_el = real_next
      end
    end

  end)
  -- process <mi> elements
  obj:traverse_elements(function(el)
    local function get_next_mi(curr)
      local next_el = curr:get_next_node()
      if next_el and next_el:is_element() then
        return next_el
      end
    end
    local function has_no_attributes(x)
      return table_count(x._attr) == 0
    end

    -- join only subsequential <mi> elements with no attributes
    if get_name(el) == "mi" and has_no_attributes(el) then
      local next_el = get_next_mi(el)
      while next_el do
        local real_next = get_next_mi(next_el)
        if get_name(next_el) == "mi" and has_no_attributes(next_el) then
          join_elements(el, next_el)
          -- set math variant to italic 
          -- (if the parent <mstyle> element doesn't set it to something else)
          update_mathvariant(el)
        else
          -- break the loop otherwise
          real_next = nil
        end
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
