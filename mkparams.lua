local lapp = require "lapp-mk4"
local mkutils = require "mkutils"
local m = {} -- use ugly module system for new lua versions support

local function get_args(parameters, optiontext)
	local parameters = parameters or {}
	parameters.progname = parameters.progname or "make4ht"
	local optiontext = optiontext or  [[
${progname} - build system for tex4ht
Usage:
make4ht [options] filename ["tex4ht.sty op." "tex4ht op." "t4ht op" "latex op"]
  -c,--config (default xhtml) Custom config file
	-d,--output-dir (default nil)  Output directory
	-l,--lua  Use lualatex for document compilation
	-s,--shell-escape Enables running external programs from LaTeX
	-u,--utf8  For output documents in utf8 encoding
	-x,--xetex Use xelatex for document compilation
	<filename> (string) Input file name
]]
  return lapp(optiontext % parameters)
end
m.get_args = get_args
return m
