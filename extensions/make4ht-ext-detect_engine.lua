-- support magic comments used by TeXShop and TeXWorks to detect used engine and format
--
local M = {}
local log = logging.new("detect engine")
local htlatex = require "make4ht-htlatex"

-- we must change build sequence when Plain TeX is requested
local change_table = {
  tex = {
    htlatex = "etex",
    command = htlatex.httex
  }, 
  pdftex = {
    htlatex = "etex",
    command = htlatex.httex
  },
  etex = {
    htlatex = "etex",
    command = htlatex.httex
  },
  luatex = {
    htlatex = "dviluatex",
    command = htlatex.httex
  },
  xetex = {
    htlatex = "xetex -no-pdf",
    command = htlatex.httex
  },
  xelatex = {
    htlatex = "xelatex -no-pdf",
  },
  lualatex = {
    htlatex = "dvilualatex",
  },
  pdflatex = {
    htlatex = "latex"
  },
  harflatex = {
    htlatex = "lualatex-dev --output-format=dvi"
  },
  harftex= {
    htlatex = "harftex --output-format=dvi",
    command = htlatex.httex
  }
}

local function find_magic_program(filename)
  -- find the magic line containing program name
  local get_comment = function(line)
    return line:match("%s*%%%s*(.+)")
  end
  local empty_line = function(line) return line:match("^%s*$") end
  for line in io.lines(filename) do
    local comment = get_comment(line)
    -- read line after line from the file, break the processing after first non comment or non empty line
    if not comment and not empty_line(line) then return nil, "Cannot find program name" end
    comment = comment or "" -- comment is nil for empty lines
    local program = comment:match("!%s*[Tt][Ee][Xx].-program%s*=%s*([^%s]+)")
    if program then return program:lower() end
  end
end

-- update htlatex entries with detected program
local function update_build_sequence(program, build_seq)
  -- handle Plain TeX
  local replaces = change_table[program] or {}
  local is_xetex = program:match("xe") -- we must handle xetex in tex4ht
  for pos, entry in ipairs(build_seq) do
    if entry.name == "htlatex" then
      -- handle httex
      entry.command = replaces.command or entry.command
      local params = entry.params or {}
      params.htlatex = replaces.htlatex or params.htlatex
      entry.params = params
    elseif is_xetex and entry.name == "tex4ht" then
      -- tex4ht must process .xdv file if the TeX file was compiled by XeTeX
      entry.params.tex4ht_par = entry.params.tex4ht_par .. " -.xdv"
    end
  end
end


function M.modify_build(make)
  -- find magic comments in the TeX file
  local build_seq = make.build_seq
  local tex_file = make.params.tex_file
  local program, msg = find_magic_program(tex_file)
  if program then
    log:info("Found program name", program)
    update_build_sequence(program, build_seq)
  else
    log:warning("Cannot find magic line with the program name")
  end
  return make
end

return M
