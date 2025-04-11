local log = logging.new "htlatex"
local autolog = logging.new "autohtlatex"

local error_logparser = require("make4ht-errorlogparser")

local Make = Make or {}
-- this function reads the LaTeX log file and tries to detect fatal errors in the compilation
local function testlogfile(par)
  local logfile = mkutils.file_in_builddir(par.input .. ".log", par)
  local f = io.open(logfile,"r")
  if not f then
    log:warning("Make4ht: cannot open log file "..logfile)
    return 1
  end
  local content = f:read("*a")
  -- test only the end of the log file, no need to run search functions on everything
  local text = content:sub(-1256)
  f:close()
  -- parse log file for all errors in non-interactive modes
  if par.interaction~="errorstopmode" then
    -- the error log parsing can be slow, so detect errors first
    -- detect both default error messages (! msg) and -file-line-number errors (filename:lineno:msg)
    if content:match("\n!") or content:match("[^:]+%:%d+%:.+")  then
      local errors, chunks = error_logparser.parse(content)
      if #errors > 0 then
        log:error("Compilation errors in the htlatex run")
        log:error("Filename", "Line", "Message")
        for _, err in ipairs(errors) do
          log:error(err.filename or "?", err.line or "?", err.error)
          log:status(err.context)
        end
      end
    end
  end
  -- info about packages with no corresponding .4ht files
  local missing_4ht = error_logparser.get_missing_4ht_files(content)
  for _, filename in ipairs(missing_4ht) do log:info("Unsupported file: " .. filename) end
  -- test for fatal errors
  if text:match("No pages of output") or text:match("TeX capacity exceeded, sorry") or text:match("That makes 100 errors") or text:match("Emergency stop") then return 1 end
  return 0
end


-- Make this function available in the build files
Make.testlogfile = testlogfile
--env.Make:add("htlatex", "${htlatex} ${latex_par} '\\\makeatletter\\def\\HCode{\\futurelet\\HCode\\HChar}\\def\\HChar{\\ifx\"\\HCode\\def\\HCode\"##1\"{\\Link##1}\\expandafter\\HCode\\else\\expandafter\\Link\\fi}\\def\\Link#1.a.b.c.{\\g@addto@macro\\@documentclasshook{\\RequirePackage[#1,html]{tex4ht}\\let\\HCode\\documentstyle\\def\\documentstyle{\\let\\documentstyle\\HCode\\expandafter\\def\\csname tex4ht\\endcsname{#1,html}\\def\\HCode####1{\\documentstyle[tex4ht,}\\@ifnextchar[{\\HCode}{\\documentstyle[tex4ht]}}}\\makeatother\\HCode '${config}${tex4ht_sty_par}'.a.b.c.\\input ' ${input}")

-- template for calling LaTeX with tex4ht loaded
Make.latex_command = "${htlatex} --interaction=${interaction} ${build_dir_arg} ${latex_par} '\\makeatletter"..
"\\def\\HCode{\\futurelet\\HCode\\HChar}\\def\\HChar{\\ifx\"\\HCode"..
"\\def\\HCode\"##1\"{\\Link##1}\\expandafter\\HCode\\else"..
"\\expandafter\\Link\\fi}\\def\\Link#1.a.b.c.{"..
"\\let\\HCode\\documentstyle\\def\\documentstyle{\\let\\documentstyle"..
"\\HCode\\expandafter\\def\\csname tex4ht\\endcsname{#1,html}\\def"..
"\\HCode####1{\\documentstyle[tex4ht,}\\@ifnextchar[{\\HCode}{"..
"\\documentstyle[tex4ht]}}\\RequirePackage[#1,html]{tex4ht}${packages}}\\makeatother\\HCode ${tex4ht_sty_par}.a.b.c."..
"\\input \"\\detokenize{${tex_file}}\"'"

Make.plain_command = '${htlatex} --interaction=${interaction} ${build_dir_arg} ${latex_par}' ..
"'\\def\\Link#1.a.b.c.{\\expandafter\\def\\csname tex4ht\\endcsname{\\expandafter\\def\\csname tex4ht\\endcsname{#1,html}\\input tex4ht.sty }}" ..
"\\def\\HCode{\\futurelet\\HCode\\HChar}\\def\\HChar{\\ifx\"\\HCode\\def\\HCode\"##1\"{\\Link##1}\\expandafter\\HCode\\else\\expandafter\\Link\\fi}" ..
"\\HCode ${tex4ht_sty_par}.a.b.c.\\input \"\\detokenize{${tex_file}}\"'"


local m = {}

function m.htlatex(par, latex_command)
  -- latex_command can be also plain_command for Plain TeX
  local command = latex_command or Make.latex_command
  local devnull = " > /dev/null 2>&1"
  if os.type == "windows" then
    command = command:gsub("'",'')
    devnull = " > nul 2>&1"
  end
  par.interaction = par.interaction or "batchmode"
  if par.builddir~="" then
      par.build_dir_arg = "--output-directory=${builddir}" % par
  else
      par.build_dir_arg = ""
  end
  if par.interaction == "batchmode" then
    command = command .. devnull
  end
  command = command % par
  log:info("LaTeX call: "..command)
  os.execute(command)
  return Make.testlogfile(par)
end

function m.httex(par)
  local newpar = {}
  for k,v in pairs(par) do newpar[k] = v end
  -- change executable name from *latex to *tex
  newpar.htlatex = newpar.htlatex:gsub("latex", "tex")
  -- plain tex command doesn't support etex extensions
  -- which are necessary for TeX4ht. just quick hack to fix this
  if newpar.htlatex == "tex" then newpar.htlatex = "etex" end
  return m.htlatex(newpar, Make.plain_command)
end


local function get_checksum(main_file, extensions, par)
  -- make checksum for temporary files 
  local checksum = "" 
  local extensions = extensions or {"aux", "4tc", "xref"}
  for _, ext in ipairs(extensions) do
    local filename = mkutils.file_in_builddir(main_file .. "." .. ext, par)
    local f = io.open(filename, "r")
    if f then
      local content = f:read("*all")
      f:close()
      -- make checksum of the file and previous checksum 
      -- this way, we will detect change in any file 
      checksum = md5.sumhexa(checksum .. content)
    end
  end
  return checksum
end

-- this function runs htlatex multiple times until the checksum of temporary files doesn't change
Make:add("autohtlatex", function(par)
  -- get checksum of temp files before compilation 
  local options = get_filter_settings "autohtlatex"
  local extensions = par.auto_extensions or options.auto_extensions or {"aux", "4tc", "xref"}
  local max_compilations  = par.max_compilations or options.max_compilations or  5
  local checksum = get_checksum(par.input, extensions, par)
  local status = m.htlatex(par)
  -- stop processing on error 
  if status ~= 0 then
    autolog:info("Stopping after first run, with status: " .. status)
    return status
  end
  -- get checksum after compilation 
  local newchecksum = get_checksum(par.input, extensions, par)
  -- this is needed to prevent possible infinite loops 
  local compilation_count = 1
  while checksum ~= newchecksum do
    -- stop processing if we reach maximum number of compilations
    if compilation_count > max_compilations then
      autolog:info("Stopping after " .. max_compilations .. " compilations")
      return status
    end
    status = m.htlatex(par)
    -- stop processing on error 
    if status ~= 0 then return status end
    checksum = newchecksum
    -- get checksum after compilation 
    newchecksum = get_checksum(par.input, extensions, par)
    compilation_count = compilation_count + 1
  end
  return status
end)

return m
