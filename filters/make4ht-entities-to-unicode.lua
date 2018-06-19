-- convert Unicode characters encoded as XML entities back to Unicode

local utfchar = unicode.utf8.char
return  function(content)
  return content:gsub("%&%#x([A-Fa-f0-9]+);", function(entity)
    -- convert hexadecimal entity to Unicode
    return utfchar(tonumber(entity, 16))
  end)
end
