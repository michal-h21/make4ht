-- convert Unicode characters encoded as XML entities back to Unicode

local utfchar = unicode.utf8.char
-- list of disabled characters
local disabled = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;"}
return  function(content)
   local content = content:gsub("%&%#x([A-Fa-f0-9]+);", function(entity)
    -- convert hexadecimal entity to Unicode
    local char_number = tonumber(entity, 16)
    -- fix for non-breaking spaces, LO cannot open file when they are present as Unicode
    if char_number == 160 then return  "&#xA0;" end
    local newchar =  utfchar(char_number)
    -- we don't want to break XML validity with forbidden characters
    return disabled[newchar] or newchar
  end)
  return content
end
