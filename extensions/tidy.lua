local M = {}

function M.test(format)
  if format == "odt" then return false end
  return true
end

return M
