local lapp = require "lapp-mk4"
local mkutils = require "mkutils"
local m = {} -- use ugly module system for new lua versions support
local log = logging.new "mkparams"

-- these two variables will be used in the version number
-- progname will be set in get_args
m.progname = "make4ht"
-- set the version number before call to process_args()
m.version_number = "v0.1"

m.optiontext =  [[
${progname} - build system for TeX4ht
Usage:
${progname} [options] filename ["tex4ht.sty op."] ["tex4ht op."] ["t4ht op"] ["latex op"]

Available options:
  -a,--loglevel (default status) Set log level.
                possible values: debug, info, status, warning, error, fatal
  -b,--backend (default tex4ht) Backend used for xml generation. 
                possible values: tex4ht or lua4ht
  -c,--config (default xhtml) Custom config file
  -d,--output-dir (default nil)  Output directory
  -B,--build-dir (default nil)  Build directory
  -e,--build-file (default nil)  If build file is different than `filename`.mk4
  -f,--format  (default html5)  Output file format
  -h,--help  Display this message
  -j,--jobname (default nil)  Set the jobname
  -l,--lua  Use lualatex for document compilation
  -m,--mode (default default) Switch which can be used in the makefile 
  -n,--no-tex4ht Disable dvi file processing with the tex4ht command
  -s,--shell-escape Enables running external programs from LaTeX
  -u,--utf8  [obsolete] The document is generated in UTF8 encoding by default
  -v,--version  Display version number
  -x,--xetex Use xelatex for document compilation
]]

-- test if the current command line argument should be passed to tex4ht, t4ht or latex
local function is_escapedargument(arg)
  -- we need to ignore make4ht options which can be used without filename, ie --version and --help
  local ignored_options = {["-h"]=true, ["--help"]=true, ["-v"] = true, ["--version"]=true}
  if ignored_options[arg] then return false end
  -- in other cases, match if the argument starts with "-" character
  return arg:match("^%-.+")
end
local function get_args(parameters, optiontext)
	local parameters = parameters or {}
	parameters.progname = parameters.progname or "make4ht"
  parameters.issue_tracker = parameters.issue_tracker or "https://github.com/michal-h21/make4ht/issues"
	parameters.postparams = parameters.postparams or ""
	local optiontext = optiontext or m.optiontext
	parameters.postfile = parameters.postfile or ""
	optiontext = optiontext .. parameters.postparams ..[[  <filename> (string) Input file name
 
Positional optional argumens:
  ["tex4ht.sty op."]  Additional parameters for tex4ht.sty
  ["tex4ht op."]      Options for tex4ht command
  ["t4ht op"]         Options for t4ht command
  ["latex op"]        Additional options for LaTeX

Documentation:                  https://tug.org/applications/tex4ht/mn.html
Issue tracker for tex4ht bugs:  https://puszcza.gnu.org.ua/bugs/?group=tex4ht
Issue tracker for ${progname} bugs: ${issue_tracker}
  ]] .. parameters.postfile 
  -- we can pass arguments for tex4ht and t4ht after filename, but it will confuse lapp, thinking that these 
  -- options are for make4ht. this may result in execution error or wrong option parsing
  -- as fix, add a space before options at the end (we need to stop to add spaces as soon as we find
  -- nonempty string which doesn't start with - it will be filename or tex4ht.sty options
  if #arg > 1 then -- do this only if more than one argument is used
    for i=#arg,1,-1 do
      local current = arg[i]
      if is_escapedargument(arg[i]) then
        arg[i] = " ".. arg[i]
      -- empty parameter
      elseif current == "" then
      else
        break
      end
    end
  end
	--print("--------------\n" .. optiontext .."--------------\n")
	return lapp(optiontext % parameters)
end

--- get outptut file format and list of extensions from --format option string
local function get_format_extensions(format_string)
  local format, rest = format_string:match("^([a-zA-Z0-9]+)(.*)")
  local extensions = {}
  -- it is possible to pass only the extensions
  rest = rest or format_string
  rest:gsub("([%+%-])([^%+^%-]+)",function(typ, name)
    table.insert(extensions, {type = typ, name = name})
  end)
  return format, extensions
end


-- try to make safe filename 
local function escape_filename(input)
  -- quoting don't work on Windows, so we will just
  if os.type == "windows" then
    return '"' .. input .. '"'
  else
    -- single quotes are safe in Unix
    return "'" .. input .. "'"
  end
end

-- detect if user specified -jobname in arguments to the TeX engine
-- or used the --jobname option for make4ht
local function handle_jobname(input, args)
  -- parameters to the TeX engine
  local latex_params = {}
  local latex_cli_params = args[4] or ""
  -- use the jobname as input name if it is specified
  local jobname = args.jobname ~="nil" and args.jobname or nil
  if jobname or not latex_cli_params:match("%-jobname") then
    -- prefer jobname over input
    input = jobname or input
    -- we must strip out directories from jobname when full path to document is given
    input = input:match("([^%/^%\\]+)$")
    -- input also cannot contain spaces, replace them with underscores
    input = input:gsub("%s", "_")
    table.insert(latex_params,"-jobname=".. escape_filename(input))
  else
    -- when user specifies -jobname, we must change name of the input file,
    -- in order to be able to process correct dvi file with tex4ht and t4ht
    local newinput
    -- first contains quotation character or first character of the name
    local first, rest = latex_cli_params:match("%-jobname%s*=?%s*(.)(.*)")
    if first=='"' then
      newinput=rest:match('([^"]+)')
    elseif first=="'" then
      newinput=rest:match("([^']+)")
    elseif type(first)== "string" then
      -- if the jobname is unquoted, it cannot contain space
      -- join the first character and rest
      rest = first.. rest
      newinput = rest:match("([^ ]+)")
    end
    if newinput then
      input = newinput
    end
  end
  -- 
	table.insert(latex_params, latex_cli_params)
  return latex_params, input
end

local function tex_file_not_exits(tex_file)
  -- try to find the input file, return false if we cannot find it
  return not (kpse.find_file(tex_file, "tex") or kpse.find_file(tex_file .. ".tex", "tex"))
end

-- use standard input instead of file if the filename is just `-`
-- return the filename and status if it is a tmp name
local function handle_input_file(filename)
  -- return the original file name if it isn't just dash
  if filename ~= "-" then return filename, false end
  -- generate the temporary name. the added extension is important
  local tmp_name = os.tmpname()
  local contents = io.read("*all")
  local f = io.open(tmp_name, "w")
  f:write(contents)
  f:close()
  return tmp_name, true
end

local function process_args(args)
	local function get_inserter(args,tb)
		return function(key, value)
			--local v = args[key] and value or ""
			local v = ""
			if args[key] then v = value end
			table.insert(tb,v)
		end
	end

  -- set error log level
  logging.set_level(args.loglevel)
  -- the default LaTeX --interaction parameter
  local interaction = "batchmode"
  if args.loglevel == "debug" then
    interaction = "errorstopmode"
  end

  if args.version ==true then
    print(string.format("%s version %s", m.progname, m.version_number))
    os.exit()
  end

	local outdir = ""
	local packages = ""

	if  args["output-dir"] ~= "nil" then
		outdir =  args["output-dir"]  or ""
		outdir = outdir:gsub('\\','/')
		outdir = outdir:gsub('/$','')
	end

	local builddir = ""

	if  args["build-dir"] ~= "nil" then
		builddir =  args["build-dir"]  or ""
		builddir = builddir:gsub('\\','/')
		builddir = builddir:gsub('/$','')
	end

  -- make4ht now requires UTF-8 output, because of DOM filters
  -- numeric entites are expanded to Unicode characters. These
  -- characters would be displayed incorrectly in 8 bit encodings.

  args.utf8 = true

	if args.backend == "lua4ht" then
		args.lua = true
		args.xetex = nil
		args.utf8 = true
		args["no-tex4ht"] = true
		packages = packages .."\\RequirePackage{lua4ht}"
	end


	local compiler = args.lua and "dvilualatex" or args.xetex and "xelatex --no-pdf" or "latex"
  local tex_file, is_tmp_file = handle_input_file(args.filename)
  -- test if the file exists
  if not is_tmp_file and tex_file_not_exits(tex_file) then
    log:warning("Cannot find input file: " .. tex_file)
  end
	local input = mkutils.remove_extension(tex_file)
  -- the output file name can be influneced using -jobname parameter passed to the TeX engine
	local latex_params, input = handle_jobname(input, args) 
	local insert_latex = get_inserter(args,latex_params)
	insert_latex("shell-escape","-shell-escape")
	--table.insert(latex_params,args["shell-escape"] and "-shell-escape")


	local t4sty = args[1] or ""
	-- test if first option is custom config file
	local cfg_tmp = t4sty:match("([^,^ ]+)")
	if cfg_tmp and cfg_tmp ~= args.config then
		local fn = cfg_tmp..".cfg"
		local f = io.open(fn,"r")
		if f then 
			args.config = cfg_tmp 
			f:close()
		end
	end
	--[[if args[1] and args[1] ~= "" then 
	t4sty = args[1] 
	else
	--]]
	-- Different behaviour from htlatex
	local utf = args.utf8 and ",charset=utf-8" or ""
	t4sty = args.config .. "," .. t4sty .. utf
	--end

	local tex4ht = ""
  local dvi= args.xetex and "xdv" or "dvi"
	if args[2] and args[2] ~="" then
		tex4ht = args[2]
	else
		tex4ht = args.utf8 and " -cmozhtf -utf8" or ""
	end
  -- set the correct extension for tex4ht if xetex is used
  if args.xetex then tex4ht = tex4ht .. " -.xdv" end

	local t4ht = args[3] or ""

	local mode = args.mode or "default"

	local build_file = input.. ".mk4"

	if args["build-file"] and args["build-file"] ~= "nil" then
		build_file = args["build-file"]
	end

  local outformat, extensions
  if args["format"] and arg["format"] ~= "nil" then
    outformat, extensions = get_format_extensions(args["format"])
  end

	local parameters = {
		htlatex = compiler
		,input=input
        ,tex_file=tex_file
		,packages=packages
		,latex_par=table.concat(latex_params," ")
		--,config=ebookutils.remove_extension(args.config)
		,tex4ht_sty_par=t4sty
		,tex4ht_par=tex4ht
		,t4ht_par=t4ht
		,mode = mode
    ,dvi = dvi
    ,build_file = build_file
    ,output_format = outformat
    ,extensions = extensions
    ,is_tmp_file = is_tmp_file
    ,interaction = interaction
		--,t4ht_dir_format=t4ht_dir_format
	}
	if outdir then parameters.outdir = outdir end
	if builddir then parameters.builddir = builddir end
	log:info("Output dir: "..outdir)
	log:info("Compiler: "..compiler)
	log:info("Latex options: ".. table.concat(latex_params," "))
	log:info("tex4ht.sty: "..t4sty)
	log:info("tex4ht: "..tex4ht)
	log:info("build_file: ".. build_file)
  if outformat~="nil" then
    log:info("Output format: ".. outformat) 
    for _, ex in ipairs(extensions) do
      log:info("Extension: ".. ex.type .. ex.name)
    end
  end
	return parameters
end
m.get_args = get_args
m.get_format_extensions = get_format_extensions
m.process_args = process_args
return m
