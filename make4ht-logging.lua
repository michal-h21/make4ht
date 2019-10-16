-- logging system for make4ht
-- inspired by https://github.com/rxi/log.lua
local logging = {}

local levels = {}
-- level of bugs that should be shown
local show_level = 1
local max_width = 0

logging.use_colors = true

logging.modes = {
  {name = "debug", color = 34},
  {name = "info", color = 32},
  {name = "warning", color = 33}, 
  {name = "error", color = 31},
  {name = "fatal", color = 35}
}

-- prepare table with mapping between mode names and corresponding levels

function logging.prepare_levels(modes)
  local modes = modes or logging.modes
  logging.modes = modes
  for level, mode in ipairs(modes) do
    levels[mode.name] = level
    max_width = math.max(string.len(mode.name), max_width)
  end
end

-- the logging level is set once
function logging.set_level(name)
  local level = levels[name] or 1
  show_level = level
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
  local obj = {module = module}
  obj.__index = obj
  -- make a function for each mode
  for _, mode in ipairs(logging.modes) do
    local name = mode.name
    local color = mode.color
    obj[name] = function(self, msg)
      -- max width is saved in logging.prepare_levels
      logging.print_msg(string.upper(name),  string.format("%s: %s", self.module, msg), color)
    end
  end
  return setmetatable({}, obj)

end


-- prepare default levels
logging.prepare_levels()

-- for _, mode in ipairs(logging.modes) do
--   logging.print_msg(mode.name,"xxxx",  mode.color)
-- end

-- local cls = logging.new("sample")
-- cls:warning("hello")
-- cls:error("world")

return logging
  


