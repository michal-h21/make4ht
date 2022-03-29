local M = {}

local log = logging.new "tidy"
function M.test(format)
  if format == "odt" then return false end
  return true
end

local empty_elements = {
  area=true,
  base=true,
  br=true,
  col=true,
  embed=true,
  hr=true,
  img=true,
  input=true,
  keygen=true,
  link=true,
  meta=true,
  param=true,
  source=true,
  track=true,
  wbr=true,
}

-- LuaXML cannot read HTML with unclosed tags (like <meta name="hello" content="world">)
-- Tidy removes end slashes in the HTML output, so
-- this function will add them back
local function close_tags(s)
  return s:gsub("<(%w+)([^>]-)>", function(tag, rest)
    local endslash = ""
    if empty_elements[tag] then endslash = " /" end
    return string.format("<%s%s%s>", tag, rest, endslash)
  end)
end
    


function M.modify_build(make)
  make:match("html?$", function(filename, par)
    local settings = get_filter_settings "tidy" or {}
    par.options = par.options or settings.options or "-utf8 -w 512 -ashtml -q"
    local command = "tidy ${options}  ${filename}" % par
    log:info("running tidy: ".. command)
    -- os.execute(command)
    local run, msg = io.popen(command, "r")
    local result = run:read("*all")
    run:close()
    if not result or  result == "" then
      log:warning("Cannot execute Tidy command")
      return nil
    end
    result = close_tags(result)
    local f = io.open(filename, "w")
    f:write(result)
    f:close()
  end)
  return make
end

return M
