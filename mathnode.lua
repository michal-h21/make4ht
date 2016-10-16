-- local mathnodepath = os.getenv "mathjaxnodepath"
-- 
-- print("mathnode", mathnodepath)
local mkutils = require "mkutils"
-- other possible value is page2svg
local mathnodepath = "page2html"
-- options for MathJax command
local options = "--format MathML"
local function compile(src)
  local tmpfile = os.tmpname()
  local filename = src
  print("Compile using MathJax")
  local command =  mathnodepath .. " ".. options .. " < " .. filename .. " > " .. tmpfile
  print(command)
  local status = os.execute(command) 
  print("Result written to: ".. tmpfile)
  mkutils.cp(tmpfile, src)
  os.remove(tmpfile)
end

local function extract_css(file)
  local f = io.open(file, "r")
  local contents = f:read("*all")
  f:close()
  local css = ""
  local filename = ""
  contents = contents:gsub('<style id="(MathJax.-)">(.+)</style>', function(name, style)
    css = style
    filename = (name or "") .. ".css"
    return '<link rel="stylesheet" type="text/css" href="'..filename ..'" />'
  end)
  local x = assert(io.open(file, "w"))
  x:write(contents)
  x:close()
  return filename, css
end

local function save_css(filename, css)
  local f = io.open(filename, "w")
  f:write(css)
  f:close()
end

return function(text, arguments)
  -- if arguments.prg then mathnodepath = arguments.prg end
  mathnodepath = arguments.prg or mathnodepath
  options      = arguments.options or options
  compile(text)
  filename, css = extract_css(text)
  save_css(filename, css)
  -- print(css)
  print(filename)
end
