local function id_colons(obj)
  -- replace : characters in links and ids with unserscores
  obj:traverse_elements(function(el) 
    local name = string.lower(obj:get_element_name(el))
    if name == "a" then
      local href = el:get_attribute("href")
      -- don't replace colons in external links
      if href and not href:match("[a-z]%://") then
        local base, id = href:match("(.*)%#(.*)")
        if base and id then
          id = id:gsub(":", "_")
          el:set_attribute("href", base .. "#" .. id)
        end
      end
    end
    local id  = el:get_attribute("id")
    if id then
      el:set_attribute("id", id:gsub(":", "_"))
    end
  end)
  return obj
end

return id_colons
