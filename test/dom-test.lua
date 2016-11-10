require "busted.runner" ()
kpse.set_program_name "luatex"

local dom = require "make4ht-dom"

local document = [[
<html>
<head><title>pokus</title></head>
<body>
<h1>pokus</h1>
<p>nazdar</p>
</body>
</html>
]]

local obj = dom.parse(document)
obj:traverse_elements(function(el)
  if obj:get_element_name(el) == "p" then
    print(el:root_node():get_element_type())
    print(el:get_element_name(), el:is_element())
    print(el:serialize())
    el:remove_node(el)
  end
end)

print(obj:serialize())

