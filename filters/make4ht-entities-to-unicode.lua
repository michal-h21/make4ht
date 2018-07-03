-- convert Unicode characters encoded as XML entities back to Unicode

-- list of disabled characters
local disabled = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }
local utfchar = unicode.utf8.char
return  function(content)
  return content:gsub("%&%#x([A-Fa-f0-9]+);", function(entity)
    -- convert hexadecimal entity to Unicode
    local newchar =  utfchar(tonumber(entity, 16))
    -- we don't want to break XML validity with forbidden characters
    return disabled[newchar] or newchar
  end)
end
