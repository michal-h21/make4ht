local m = {}

local function get_filename(chunk)
  local filename = chunk:match("([^\n^%(]+)") 
  if not filename then 
    return false, "No filename detected"
  end
  local first = filename:match("^[%./\\]+")
  if first then return filename end
  return false
end

local function get_chunks(text)
  -- parse log for particular included files
  local chunks = {}
  -- each file is enclosed in matching () brackets
  local newtext = text:gsub("(%b())", function(a)
    local chunk = string.sub(a,2,-2)
    -- if no filename had been found in the chunk, it is probably not file chunk
    -- so just return the original text
    local filename = get_filename(chunk)
    if not filename then return a end
    local children, text = get_chunks(chunk)
    table.insert(chunks, {filename = filename, text = text, children = children})
    return ""
  end)
  return chunks, newtext
end


function print_chunks(chunks, level)
  local level = level or 0
  local indent = string.rep("  ", level)
  for k,v in ipairs(chunks) do
    print(indent .. (v.filename or "?"), string.len(v.text))
    print_chunks(v.children, level + 1)
  end
end

local function parse_default_error(lines, i)
  local line = lines[i]
  -- get the error message "! msg text"
  local err = line:match("^!(.+)")
  -- the next line should contain line number where error happened
  local next_line = lines[i+1] or ""
  local msg = {}
  -- get the line number and first line of the error context
  local line_no, msg_start = next_line:match("^l%.(%d+)(.+)") 
  line_no = line_no or false 
  msg_start = msg_start or ""
  msg[#msg+1] = msg_start .. " <-"
  -- try to find rest of the error context. 
  for x = i+2, i+5 do
    local next_line = lines[x] or ""
    -- break on blank lines
    if next_line:match("^%s*$") then break end
    msg[#msg+1] = next_line:gsub("^%s*", ""):gsub("%s$", "")
  end
  return err, line_no, table.concat(msg, " ")
end

local  function parse_linenumber_error(lines, i)
  -- parse errors from log created with the -file-line-number option
  local line = lines[i]
  local filename, line_no, err = line:match("^([^%:]+)%:(%d+)%:%s*(.*)")
  local msg = {}
  -- get error context
  for x = i+1, i+2 do
    local next_line = lines[x] or ""
    -- break on blank lines
    if next_line:match("^%s*$") then break end
    msg[#msg+1] = next_line:gsub("^%s*", ""):gsub("%s$", "")
  end
  -- insert mark to the error
  if #msg > 1 then
    table.insert(msg, 2, "<-")
  end
  return err, line_no, table.concat(msg, " ")
end

--- get error messages, linenumbers and contexts from a log file chunk
---@param text string chunk from the long file where we should find errors
---@return table errors error messages
---@return table error_lines error line number 
---@return table error_messages error line contents
local function parse_errors(text)
  local lines = {}
  local errors = {}
  local find_line_no = false
  local error_lines = {}
  local error_messages = {}
  for line in text:gmatch("([^\n]+)") do
    lines[#lines+1] = line
  end
  for i = 1, #lines do
    local line = lines[i]
    local err, line_no, msg
    if line:match("^!(.+)") then
      err, line_no, msg = parse_default_error(lines, i)
    elseif line:match("^[^%:]+%:%d+%:.+") then
      err, line_no, msg = parse_linenumber_error(lines, i)
    end
    if err then
      errors[#errors+1] = err
      error_lines[#errors] = line_no
      error_messages[#errors] = msg
    end
  end
  return errors, error_lines, error_messages
end


local function get_errors(chunks, errors)
  local errors =  errors or {}
  for _, v in ipairs(chunks) do
    local current_errors, error_lines, error_contexts = parse_errors(v.text)
    for i, err in ipairs(current_errors) do
      table.insert(errors, {filename = v.filename, error = err, line = error_lines[i], context = error_contexts[i] })
    end
    errors = get_errors(v.children, errors)
  end
  return errors
end

function m.get_missing_4ht_files(log)
  local used_files = {}
  local used_4ht_files = {}
  local missing_4ht_files = {}
  local pkg_names = {sty=true, cls=true}
  for filename, ext in log:gmatch("[^%s]-([^%/^%\\^%.%s]+)%.([%w][%w]+)") do
    -- break ak
    if ext == "aux" then break end
    if pkg_names[ext] then
      used_files[filename .. "." .. ext] = true
    elseif ext == "4ht" then
      used_4ht_files[filename] = true
    end
  end
  for filename, _ in pairs(used_files) do
    if not used_4ht_files[mkutils.remove_extension(filename)] then
      table.insert(missing_4ht_files, filename)
    end
  end
  return missing_4ht_files
end


function m.parse(log)
  local chunks, newtext = get_chunks(log)
  -- save the unparsed text that contains system messages
  table.insert(chunks, {text = newtext, children = {}})
  -- print_chunks(chunks)
  local errors = get_errors(chunks)
  -- for _,v in ipairs(errors) do 
    -- print("error", v.filename, v.line, v.error)
  -- end
  return errors, chunks
end


m.print_chunks = print_chunks

return m
