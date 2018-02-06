local function id_colons(obj)
  -- replace : characters in links and ids with unserscores
  obj:traverse_elements(function(el) 
    local name = string.lower(obj:get_element_name(el))
    if name == "a" then
      local href = obj:get_attribute(el, "href")
      if href and not href:match("[a-z]%://") then
        obj:set_attribute(el, "href", href:gsub(":", "_"))
      end
    end
    local id  = obj:get_attribute( el , "id")
    if id then
      obj:set_attribute(el, "id", id:gsub(":", "_"))
    end
    -- local id = obj:get_attribute(el, "id")
  end)
  return obj
end

return id_colons
