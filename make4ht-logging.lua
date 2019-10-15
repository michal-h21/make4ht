-- logging system for make4ht
--
local logging = {}


local modes = {
  {name = "debug"},
  {name = "info"},
  {name = "warning"}, 
  {name = "error"},
  {name = "fatal"}
}


logging.new = function()

end


return logging
  


