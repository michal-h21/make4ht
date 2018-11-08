local charclases = {
  span=true,
  mn = true,
}

local function join_characters(obj,par)
  -- join adjanced span and similar elements inserted by 
  -- tex4ht to just one object.
  local par = par or {}
  local options = get_filter_settings "joincharacters"
  local charclases = options.charclases or par.charclases or charclases

  obj:traverse_elements(function(el)
    local get_name = function(curr) 
      return string.lower(curr:get_element_name())
    end
    local get_class = function(next_el)
      return next_el:get_attribute("class")
    end
    local is_span = function(next_el)
      return charclases[get_name(next_el)]
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
    -- processed elements (charclases)
    if is_span(el) then
      local next_el = get_next(el)
      -- loop over the following elements and test whether they are of the same type
      -- as the current one
      while  next_el do
        -- save the next element because we will remove it later
        local real_next = get_next(next_el)
        if get_name(el) == get_name(next_el) and get_class(el) == get_class(next_el) and not el:get_attribute("id") then
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
