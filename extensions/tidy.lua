local M = {}

function M.test(format)
  if format == "odt" then return false end
  return true
end

function M.modify_build(make)
  make:match("html$", "tidy -m -xml -utf8 -q -i ${filename}")
  return make
end

return M
