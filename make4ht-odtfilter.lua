local mkutils = require "mkutils"
local zip = require "zip"


-- use function to change contents of the ODT file
local function update_odt(odtfilename, file_path, fn)
  -- get name of the odt file
  local odtname = mkutils.remove_extension(odtfilename) .. ".odt"
  -- open and read contents of the requested file inside ODT file
  local odtfile = zip.open(odtname)
  local local_file = odtfile:open(file_path)
  local content = local_file:read("*all")
  local_file:close()
  odtfile:close()
  -- update the content using user function
  content = fn(content)
  -- write the updated file
  local local_file_file  = io.open(file_path,"w")
  local_file_file:write(content)
  local_file_file:close()
  os.execute("zip " .. odtname .. " " .. file_path)
  os.remove(file_path)
end

Make:match("tmp$", function(name, par)
  update_odt(name, "content.xml", function(content)
    return content:gsub("%&%#x([A-Fa-f0-9]+);", function(entity)
      -- convert hexadecimal entity to Unicode
      print(entity,utfchar(tonumber(entity, 16)))
      return utfchar(tonumber(entity, 16))
    end)
  end)
end)
