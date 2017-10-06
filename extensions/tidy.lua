local M = {}

function M.test(format)
  if format == "odt" then return false end
  return true
end

function M.modify_build(make)
  make:match("html$", "tidy -m -utf8 -w 512 -q ${filename}")
  return make
end

return M
