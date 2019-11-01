-- use Latexmk in first LaTeX call
-- only in the first call, because we don't need to execute  biber, etc. in the subsequent
-- LaTeX calls, these are only for resolving the cross-references
local M = {}
function M.modify_build(make)
  local used = false
  local first 
  local build_seq = make.build_seq
  -- find first htlatex call in the build sequence
  for pos,v in ipairs(build_seq) do
    if v.name == "htlatex" and not first then
      first = pos
    end
  end
  -- if htlatex was found
  if first then
    -- add dummy latexmk call to the build sequence
    make:latexmk {}
    -- replace name, command and type in the first htlatex
    -- call with values from the dummy latexmk call
    local replaced = build_seq[first]
    local latexmk = build_seq[#build_seq]
    replaced.name = latexmk.name
    replaced.command = latexmk.command
    replaced.type = latexmk.type
    -- remove the dummy latexmk
    table.remove(build_seq)
  end
  return make
end
return M
