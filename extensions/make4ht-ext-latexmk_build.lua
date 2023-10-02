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
  -- we need to save contents of the .tmp file, to prevent extra executions from latexmk
  -- tex4ht command overwrites content that was set by LaTeX with it's own stuff
  local tmp_file 
  make:add("save_tmp", function(par)
    local f = io.open(mkutils.file_in_builddir(par.input .. ".tmp", par), "r")
    if f then
      tmp_file = f:read("*all")
      f:close()
    end
    return 0
  end)
  make:add("load_tmp", function(par)
    if tmp_file then
      local f = io.open(mkutils.file_in_builddir(par.input .. ".tmp", par), "w")
      if f then
        f:write(tmp_file)
      end
    end
    return 0
  end)
  -- if htlatex was found
  if first then
    -- handle tmp file
    make:load_tmp {}
    make:save_tmp {}
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
  -- remove htlatex calls from the build sequence, they are unnecessary
  local new_build_seq = {}
  for pos, v in ipairs(build_seq) do
    if v.name ~= "htlatex" and v.name ~= "tex4ht" then
      table.insert(new_build_seq, v)
    elseif v.name == "tex4ht" then
      -- insert save_tmp before tex4ht
      table.insert(new_build_seq, build_seq[#build_seq])
      -- remove save_tmp from the end
      table.remove(build_seq)
      -- and now insert tex4ht
      table.insert(new_build_seq, v)
    end
  end
  make.build_seq = new_build_seq
  return make
end
return M
