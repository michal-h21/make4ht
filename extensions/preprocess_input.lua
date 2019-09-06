-- preprocess R literate sources or Markdown files to LaTeX
local M = {}

M.modify_build = function(make)
  make:add("preprocess_input", function(arg)
    print "***************************"
    print("Hello preprocess")
    print "***************************"
  end, {})
  make:preprocess_input {}
  -- the preprocess_input is now on the last position in the build process. 
  -- it needs to be moved to the first place
  local build_seq = make.build_seq
  local preprocess = table.remove(build_seq) -- remove from the last place
  table.insert(build_seq, 1, preprocess)
  return make

  

end

return M
