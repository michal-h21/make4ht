-- This file generates Lua table with mapping of Unicode charcodes for different math font styles (bold, italic, bold-italic, etc.)
-- The new version of MathML requires to use different charcodes for different font styles, 
-- so we need to replace characters in the MathML output depending on the value of the mathvariant attribute.

kpse.set_program_name "luatex"
local unicode = kpse.find_file("UnicodeData.txt")

local function get_chartype(chartype)
  -- remove the extra information from the chartype and convert it to the format used in the mathvariant attribute
  return chartype:gsub("MATHEMATICAL ", "")
    :gsub("SYMBOL$", "")
    :gsub("%a+%s*$", "")
    :gsub("SMALL ", "")
    :gsub("CAPITAL ", "")
    :gsub("%s+$", "")
    :gsub("%s+", "-")
    :lower()
end


local function parse_unicode(unicode)
  local unicode_data = {}
  for line in io.lines(unicode) do
    -- parse the UnicodeData.txt file to get the base code for the mathematical symbols
    local code, chartype, basecode = line:match("^(%x+);([^;]+);[^;]+;[^;]+;[^;]+;([^;]+);")
    -- we are interested only in the mathematical symbols
    if code and chartype:match("^MATHEMATICAL") then
      -- the basecode contains extra <font> tag, we need to remove it and convert the hexadecimal number to decimal
      local base = tonumber(basecode:match("(%x+)$"), 16)
      -- remove the extra information from the chartype
      chartype = get_chartype(chartype)
      local char = tonumber(code, 16)
      if base and char then
        -- we need to store corresponding base code for each symbol in the current font style
        local area = unicode_data[base] or {}
        area[chartype] = char
        unicode_data[base] = area
        -- print("unicode", char, chartype, base)
      end
    end
  end
  return unicode_data
end

local unicode_data = parse_unicode(unicode)

print "-- This file is autogenerated from tools/make_mathmlchardata.lua"
print "return {"

local to_sort = {}
for base, data in pairs(unicode_data) do
  local fields = {}
  for chartype, char in pairs(data) do
    fields[#fields+1] = string.format("['%s']=%s", chartype, char)
  end
  to_sort[#to_sort+1] = string.format("[%05i] = {%s},", base, table.concat(fields, ", "))
end

-- sort characters
table.sort(to_sort)
for _, line in ipairs(to_sort) do print(line) end

print "}"
