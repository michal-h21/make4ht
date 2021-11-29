-- logging system for make4ht
-- inspired by https://github.com/rxi/log.lua
local logging = {}

local levels = {}
-- level of bugs that should be shown
-- enable querying of current log level
logging.show_level = 1
local max_width = 0
local max_status = 0

logging.use_colors = true

logging.modes = {
  {name = "debug", color = 34},
  {name = "info", color = 32},
  {name = "status", color = 37},
  {name = "warning", color = 33}, 
  {name = "error", color = 31, status = 1},
  {name = "fatal", color = 35, status = 2}
}

-- prepare table with mapping between mode names and corresponding levels

function logging.prepare_levels(modes)
  local modes = modes or logging.modes
  logging.modes = modes
  for level, mode in ipairs(modes) do
    levels[mode.name] = level
    mode.level = level
    max_width = math.max(string.len(mode.name), max_width)
  end
end

-- the logging level is set once
function logging.set_level(name)
  local level = levels[name] or 1
  logging.show_level = level
end

function logging.print_msg(header, message, color)
  local color = color or 0
  -- use format for collors depending on the use_colors option
  local header = "[" .. header .. "]"
  local color_format =  logging.use_colors and string.format("\27[%im%%s\27[0m%%s", color) or "%s%s"
  -- the padding is maximal mode name width + brackets + space
  local padded_header = string.format("%-".. max_width + 3 .. "s", header)
  print(string.format(color_format, padded_header, message))
end

-- 
function logging.new(module)
  local obj = {
    module = module,
    output = function(self, output)
      -- used for printing of output of commands
      if logging.show_level <= (levels["debug"] or 1) then
        print(output)
      end
    end
  }
  obj.__index = obj
  -- make a function for each mode
  for _, mode in ipairs(logging.modes) do
    local name = mode.name
    local color = mode.color
    local status = mode.status or 0
    obj[name] = function(self, ...)
      -- set make4ht exit status
      max_status = math.max(status, max_status)
      -- max width is saved in logging.prepare_levels
      if mode.level >= logging.show_level then
        -- support variable number of parameters
        local table_with_holes = table.pack(...) 
        local table_without_holes = {}
        -- trick used to support the nil values in the varargs
        -- https://stackoverflow.com/a/7186820/2467963
        for i= 1, table_with_holes.n do
          table.insert(table_without_holes, tostring(table_with_holes[i]) or "")
        end
        local msg = table.concat(table_without_holes, "\t")
        logging.print_msg(string.upper(name),  string.format("%s: %s", self.module, msg), color)
      end
    end
  end
  return setmetatable({}, obj)

end

-- exit make4ht with maximal error status
function logging.exit_status()
  os.exit(max_status)
end


-- prepare default levels
logging.prepare_levels()

-- for _, mode in ipairs(logging.modes) do
--   logging.print_msg(mode.name,"xxxx",  mode.color)
-- end

-- local cls = logging.new("sample")
-- cls:warning("hello")
-- cls:error("world")
-- cls:info("set new level")
-- logging.set_level("error")
-- cls:info("level set")
-- cls:error("just print the error")
--


return logging
  


