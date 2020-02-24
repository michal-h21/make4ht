
local M = {}
local log = logging.new "indexing"

-- Handle accented characters in files created with \usepackage[utf]{inputenc}
-- this code was originally part of https://github.com/michal-h21/iec2utf/
local enc = {}

local licrs = {}
local codepoint2utf = unicode.utf8.char 
local used_encodings = {}

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
  -- use default encodings if used doesn't provide one
  enc = enc or  {"T1","T2A","T2B","T2C","T3","T5", "LGR"}
	for _,e in pairs(enc) do
		local filename = e:lower() .. "enc.dfu"
    -- don't process an enc file multiple times
    if not used_encodings[filename] then
      local dfufile = kpse.find_file(filename)
      if dfufile then
        load_encfiles(dfufile)
      end
    end
    used_encodings[filename] = true
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
          return "\\Link[" .. entry.file .."]{".. entry.dest .."}{}" .. page .."\\EndLink{}"
        else
          return page
        end
      end)
    end)
    buffer[#buffer+1] = line 
  end
  return table.concat(buffer, "\n")
end

-- prepare the .idx file produced by tex4ht
-- for use with Xindy or Makeindex
local prepare_idx = function(filename)
  local f = io.open(filename, "r")
  if not f then return nil, "Cannot open file :".. tostring(filename) end
  local content = f:read("*all")
  local idx = parse_idx(content)
  local idxname = os.tmpname()
  local f = io.open(idxname, "w")
  f:write(idx.idx)
  f:close()
  -- return the object with mapping between dummy page numbers 
  -- and link destinations in the files, and the temporary .idx file
  -- these can be used for the processing with the index processor
  return idx, idxname
end

-- add links to a index file
local process_index = function(indname, idx)
  local f = io.open(indname,  "r")
  if not f then return  nil, "Cannot open .ind file: " .. tostring(indname) end
  local content = f:read("*all")
  f:close()

  local newcontent = fix_idx_pages(content, idx)
  local f = io.open(indname,"w")
  f:write(newcontent)
  f:close()
  return true
end

local get_idxname = function(par)
  return par.idxfile or par.input .. ".idx"
end

local prepare_tmp_idx = function(par)
  par.idxfile = get_idxname(par)
  -- construct the .ind name, based on the .idx name
  par.indfile = par.indfile or par.idxfile:gsub("idx$", "ind")
  load_enc()
  -- save hyperlinks and clean the .idx file
  local idxdata, newidxfile = prepare_idx(par.idxfile)
  if not idxdata then
    -- if the prepare_idx function returns nil, the second reuturned value contains error msg
    return nil, newidxfile
  end
  return  newidxfile, idxdata
end


local splitindex = function(par)
  local files = {}
  local idxfiles = {}
  local buffer 
  local idxfile = get_idxname(par)
  for line in io.lines(idxfile) do
    local file = line:match("indexentry%[(.-)%]")
    if file then
      -- generate idx name for the current output file
      file =  par.input .. "-" ..file .. ".idx"
      local current = files[file] or {}
      -- remove file name from the index entry
      local indexentry = line:gsub("indexentry%[.-%]", "indexentry")
      -- save the index entry and preseding line to the current buffer
      table.insert(current, buffer)
      table.insert(current, indexentry)
      files[file] = current
    end
    -- 
    buffer = line
  end
  -- save idx files
  for filename, contents in pairs(files) do
    log:info("Saving split index file: " .. filename)
    idxfiles[#idxfiles+1] = filename
    local f = io.open(filename, "w")
    f:write(table.concat(contents, "\n"))
    f:close()
  end
  return idxfiles
end

local function run_indexing_command (command, par)
  -- detect command name from the command. It will be the first word
  local cmd_name = command:match("^[%a]+") or "indexing"
  local xindylog  = logging.new(cmd_name)
  -- support split index
  local subindexes = splitindex(par)
  if #subindexes > 0 then
    -- call the command again on all files produced by splitindex
    for _, subindex in ipairs(subindexes) do
      -- make copy of the parameters
      local t = {}
      for k,v in pairs(par) do t[k] = v end
      t.idxfile = subindex
      run_indexing_command(command, t)
    end
    return nil
  end
  local newidxfile, idxdata = prepare_tmp_idx(par)
  if not newidxfile then
    -- the idxdata will contain error message in the case of error
    xindylog:warning(idxdata)
    return false
  end
  par.newidxfile = newidxfile
  xindylog:debug("Prepared temporary idx file: ", newidxfile)
  -- prepare modules
  local xindy_call = command % par
  xindylog:info(xindy_call)
  local status = mkutils.execute(xindy_call)
  -- insert correct links to the index
  local status, msg = process_index(par.indfile, idxdata)
  if not status then xindylog:warning(msg) end
  -- remove the temporary idx file
  os.remove(newidxfile)
  -- null the indfile, it is necessary in order to support
  -- multiple indices
  par.indfile = nil
end


M.get_utf8 = get_utf8
M.load_enc = load_enc
M.parse_idx = parse_idx
M.fix_idx_pages = fix_idx_pages
M.prepare_idx = prepare_idx
M.process_index = process_index
M.prepare_tmp_idx = prepare_tmp_idx
M.run_indexing_command = run_indexing_command
return M
