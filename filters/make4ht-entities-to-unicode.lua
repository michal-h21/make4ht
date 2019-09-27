-- convert Unicode characters encoded as XML entities back to Unicode

local utfchar = unicode.utf8.char
-- list of disabled characters
local disabled = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;"}
return  function(content)
   local content = content:gsub("%&%#x([A-Fa-f0-9]+);", function(entity)
    -- convert hexadecimal entity to Unicode
    local char_number = tonumber(entity, 16)
    -- don't convert entites that would produce invalid UTF-8 chars
    if char_number > 127 and char_number < 256 then return "&#x".. entity ..";" end
    local newchar =  utfchar(char_number)
    -- we don't want to break XML validity with forbidden characters
    return disabled[newchar] or newchar
  end)
  return content
end
