-- local mathnodepath = os.getenv "mathjaxnodepath"
-- 
-- print("mathnode", mathnodepath)
local mkutils = require "mkutils"
-- other possible value is page2svg
local mathnodepath = "page2html"
-- options for MathJax command
local options = "--format MathML"
-- math fonts position
-- don't alter fonts if not set
local fontdir = nil
-- if we copy fonts 
local fontdest = nil
local fontformat = "otf"

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

-- 
local function use_fonts(css)
  local family_pattern = "font%-family:%s*(.-);.-%/([^%/]+)%.".. fontformat
  local family_build = "@font-face {font-family: %s; src: url('%s/%s.%s') format('%s')}"
  local fontdir = fontdir:gsub("/$","")
  css = css:gsub("(@font%-face%s*{.-})", function(face)
    -- if not face:match("url%(") then return face end
    if not face:match("url%(") then return "" end
    -- print(face)
    local family, filename = face:match(family_pattern)
    print(family, filename)
    local newfile = string.format("%s/%s.%s", fontdir, filename, fontformat)
    Make:add_file(newfile)
    return family_build:format(family, fontdir, filename, fontformat, fontformat)
    -- return face
  end)
  return css
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
  fontdir      = arguments.fontdir or fontdir
  fontdest     = arguments.fontdest or fontdest
  fontformat   = arguments.fontformat or fontformat
  compile(text)
  filename, css = extract_css(text)
  if fontdir then
    css = use_fonts(css)
  end
  save_css(filename, css)
  Make:add_file(filename)
  -- print(css)
  print(filename)
end
