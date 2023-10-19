local log = logging.new "htlatex"

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
    if content:match("\n!")  then
      local errors, chunks = error_logparser.parse(content)
      if #errors > 0 then
        log:error("Compilation errors in the htlatex run")
        log:error("Filename", "Line", "Message")
        for _, err in ipairs(errors) do
          log:error(err.filename or "?", err.line or "?", err.error)
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

return m
