local M = {}

function M.test(format)
  if format == "odt" then return false end
  return true
end

function M.modify_build(make)
  make:match("html$", function(filename, par)
    local settings = get_filter_settings "tidy" or {}
    par.options = par.options or settings.options or "-m -utf8 -w 512 -q"
    local command = "tidy ${options}  ${filename}" % par
    print("execute: ".. command)
    os.execute(command)
  end)
  return make
end

return M
