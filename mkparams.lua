local lapp = require "lapp-mk4"
local mkutils = require "mkutils"
local m = {} -- use ugly module system for new lua versions support

m.optiontext =  [[
${progname} - build system for tex4ht
Usage:
${progname} [options] filename ["tex4ht.sty op." "tex4ht op." "t4ht op" "latex op"]
-b,--backend (default tex4ht) Backend used for xml generation. 
              possible values: tex4ht or lua4ht
-c,--config (default xhtml) Custom config file
-d,--output-dir (default nil)  Output directory
-e,--build-file (default nil)  If build file is different than `filename`.mk4
-h,-- help  Display this message
-l,--lua  Use lualatex for document compilation
-m,--mode (default default) Switch which can be used in the makefile 
-n,--no-tex4ht Disable dvi file processing with tex4ht command
-s,--shell-escape Enables running external programs from LaTeX
-u,--utf8  For output documents in utf8 encoding
-x,--xetex Use xelatex for document compilation
-v,--version  Display version number
]]
local function get_args(parameters, optiontext)
	local parameters = parameters or {}
	parameters.progname = parameters.progname or "make4ht"
	parameters.postparams = parameters.postparams or ""
	local optiontext = optiontext or m.optiontext
	parameters.postfile = parameters.postfile or ""
	optiontext = optiontext .. parameters.postparams .."<filename> (string) Input file name\n" .. parameters.postfile 
	--print("--------------\n" .. optiontext .."--------------\n")
	return lapp(optiontext % parameters)
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

  if args.version ==true then
    print "make4ht version 0.1b"
    os.exit()
  end

	local outdir = ""
	local packages = ""

	if  args["output-dir"] ~= "nil" then 
		outdir =  args["output-dir"]  or ""
		outdir = outdir:gsub('\\','/')
		outdir = outdir:gsub('/$','')
	end

	if args.backend == "lua4ht" then
		args.lua = true
		args.xetex = nil
		args.utf8 = true
		args["no-tex4ht"] = true
		packages = packages .."\\RequirePackage{lua4ht}"
	end


	local compiler = args.lua and "dvilualatex" or args.xetex and "xelatex --no-pdf" or "latex"
  local tex_file = args.filename
	local input = mkutils.remove_extension(args.filename)
	local latex_params = {}
	local insert_latex = get_inserter(args,latex_params)
	insert_latex("shell-escape","-shell-escape")
  local latex_cli_params = args[4] or ""
  if not latex_cli_params:match("%-jobname") then
    -- we must strip out directories from jobname when full path to document is given
    input = input:match("([^%/]+)$")
    table.insert(latex_params,"-jobname="..input)
  else
    -- when user specifies -jobname, we must change name of the input file,
    -- in order to be able to process correct dvi file with tex4ht and t4ht
    local newinput
    local first, rest = latex_cli_params:match("%-jobname=(.)(.*)")
    if first=='"' then
      newinput=rest:match('([^"]+)')
    elseif first=="'" then
      newinput=rest:match("([^']+)")
    elseif type(first)== "string" then
      rest = first.. rest
      newinput = rest:match("([^ ]+)")
    end
    if newinput then
      input = newinput
    end
  end
	table.insert(latex_params, latex_cli_params)
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
    if args.xetex then tex4ht = tex4ht .. " -.xdv" end
		-- tex4ht = tex4ht .. xdv
	end

	local t4ht = args[3] or ""

	local mode = args.mode or "default"

	local build_file = input.. ".mk4"

	if args["build-file"] and args["build-file"] ~= "nil" then
		build_file = args["build-file"] 
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
		--,t4ht_dir_format=t4ht_dir_format
	}
	if outdir then parameters.outdir = outdir end
	print("Output dir: ",outdir)
	print("Compiler: ", compiler)
	print("Latex options: ", table.concat(latex_params," "))
	print("tex4ht.sty :",t4sty)
	print("tex4ht",tex4ht)
	print("build_file", build_file)
	return parameters
end
m.get_args = get_args
m.process_args = process_args
return m
