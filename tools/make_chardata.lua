kpse.set_program_name "luatex"
-- create Lua module from UnicodeData
-- we need mapping to lower case letters and decomposed base letters for accented characters
local unicode_data = kpse.find_file("UnicodeData.txt")
local chardata = {}
for line in io.lines(unicode_data) do
  local record = line:explode(";")
  local char = tonumber(record[1], 16)
  local category  = string.lower(record[3])
  if category:match("^l") or category == "zs" then
    -- the decomposed field contains charcode for the base letter and accent
    -- we care only about the base letter
    local decomposed = record[6]:match("([%x]+)")
    decomposed = decomposed and tonumber(decomposed, 16)
    -- the lowercase letter is the last field
    local lower = record[#record - 1]
    lower = lower and tonumber(lower, 16) or nil
    chardata[#chardata+1] = {
      char   = char,
      shcode = decomposed,
      lccode = lower,
      category = category
    }
  end
end

print "return {"
local function add(fields, caption, value)
  if value then
    fields[#fields+1] = string.format("%s=%s", caption, value)
  end
end

for _, data in ipairs(chardata) do
  local fields = {}
  -- we need to add qotes to force string
  add(fields, "category", string.format('"%s"', data.category))
  add(fields, "lccode", data.lccode)
  add(fields, "shcode", data.shcode)
  print(string.format("[%s] = {%s},", data.char, table.concat(fields, ", ")))
end

print "}"
