
local M = {}

-- Handle accented characters in files created with \usepackage[utf]{inputenc}
-- this code was originally part of https://github.com/michal-h21/iec2utf/
local enc = {}

local licrs = {}
local codepoint2utf = unicode.utf8.char 

-- load inputenc encoding file
local function load_encfiles(f)
	local file= io.open(f,"r")
	local encodings = file:read("*all")
	file:close()
	for codepoint, licr in encodings:gmatch('DeclareUnicodeCharacter(%b{})(%b{})') do
		local codepoint = codepoint2utf(tonumber(codepoint:sub(2,-2),16))
		local licr= licr:sub(2,-2):gsub('@tabacckludge','')
		licrs[licr] = codepoint
	end
end

local function sanitize_licr(l)
	return l:gsub(" (.)",function(s) if s:match("[%a]") then return " "..s else return s end end):sub(2,-2)
end

local load_enc = function(enc)
	for _,e in pairs(enc) do
		local filename = e:lower() .. "enc.dfu"
		local dfufile = kpse.find_file(filename)
		if dfufile then
			load_encfiles(dfufile)
		end
	end
end



local cache = {}

local get_utf8 = function(input)
	local output = input:gsub('\\IeC[%s]*(%b{})',function(iec)
    -- remove \protect commands 
    local iec = iec:gsub("\\protect%s*", "")
		local code = cache[iec] or licrs[sanitize_licr(iec)] or '\\IeC '..iec
		-- print(iec, code)
		cache[iec] = code
		return code
	end)
	return output
end


-- parse the idx file produced by tex4ht
-- it replaces the document page numbers by index entry number
-- each index entry can then link to place in the HTML file where the
-- \index command had been used

local parse_idx = function(content)
  -- index entry number
  local current_entry = 0
  -- map between index entry number and corresponding HTML file and destination
  local map = {}
  local buffer = {}

  for line in content:gmatch("([^\n]+)") do
    if line:match("^\\beforeentry") then
      -- increment index entry number
      current_entry = current_entry + 1
      local file, dest = line:match("\\beforeentry{(.-)}{(.-)}")
      map[current_entry] = {file = file, dest = dest}
    elseif line:match("^\\indexentry") then
      -- replace the page number with the current
      -- index entry number
      local result = line:gsub("{[0-9]+}", "{"..current_entry .."}")
      buffer[#buffer+1] = get_utf8(result)
    else
      buffer[#buffer+1] = line
    end
  end
  -- return table with page to dest map and updated idx file
  return {map = map, idx = table.concat(buffer, "\n")}
end

-- replace page numbers in the ind file with hyperlinks
local fix_idx_pages = function(content, idxobj)
  local buffer = {}
  local entries = idxobj.map
  for  line in content:gmatch("([^\n]+)")  do
    local line = line:gsub("(%s*\\%a+.-%,)(.+)$", function(start,rest)
      return start .. rest:gsub("(%d+)", function(page)
        local entry = entries[tonumber(page)]
        if entry then
          -- construct link to the index entry
          return "\\LNK{" .. entry.file .."}{".. entry.dest .."}{}{" .. page .."}"
        else
          return page
        end
      end)
    end)
    buffer[#buffer+1] = line 
  end
  return table.concat(buffer, "\n")
end

load_enc({"T1","T2A","T2B","T2C","T3","T5", "LGR"})

M.get_utf8 = get_utf8
M.load_enc = load_enc
M.parse_idx = parse_idx
M.fix_idx_pages = fix_idx_pages
return M
