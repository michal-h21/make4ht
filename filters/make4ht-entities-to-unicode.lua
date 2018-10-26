-- convert Unicode characters encoded as XML entities back to Unicode

local utfchar = unicode.utf8.char
-- list of disabled characters
local disabled = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;"}
return  function(content)
   local content = content:gsub("%&%#x([A-Fa-f0-9]+);", function(entity)
    -- convert hexadecimal entity to Unicode
    local newchar =  utfchar(tonumber(entity, 16))
    -- we don't want to break XML validity with forbidden characters
    return disabled[newchar] or newchar
  end)
  -- the non-breaking space character cause issues in the ODT opening
  return content:gsub(string.char(160), "&#xA0;")
end
