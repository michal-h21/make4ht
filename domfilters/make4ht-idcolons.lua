local allowed_chars = {
  ["-"] = true,
  ["."] = true
}
local function fix_colons(id)
  -- match every non alphanum character
  return id:gsub("[%W]", function(s)
    -- some characters are allowed, we don't need to replace them
    if allowed_chars[s] then return s end
    -- in other cases, replace with underscore
    return "_"
  end)
end

local function id_colons(obj)
  -- replace non-valid characters in links and ids with underscores
  obj:traverse_elements(function(el) 
    local name = string.lower(obj:get_element_name(el))
    if name == "a" then
      local href = el:get_attribute("href")
      -- don't replace colons in external links
      if href and not href:match("[a-z]%://") then
        local base, id = href:match("(.*)%#(.*)")
        if base and id then
          id = fix_colons(id)
          el:set_attribute("href", base .. "#" .. id)
        end
      end
    end
    local id  = el:get_attribute("id")
    if id then
      el:set_attribute("id", fix_colons(id))
    end
  end)
  return obj
end

return id_colons
