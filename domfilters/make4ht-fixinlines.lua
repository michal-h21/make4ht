local inline_elements = {
  b=true,
  big=true,
  i=true,
  small=true,
  tt=true,
  abbr=true,
  acronym=true,
  cite=true,
  code=true,
  dfn=true,
  em=true,
  kbd=true,
  strong=true,
  samp=true,
  time=true,
  var=true,
  a=true,
  bdo=true,
  br=true,
  img=true,
  map=true,
  object=true,
  q=true,
  script=true,
  span=true,
  sub=true,
  sup=true,
  button=true,
  input=true,
  label=true,
  select=true,
  textarea=true,
  mn=true,
  mi=true
}


local function fix_inlines(obj)
  local settings = get_filter_settings "fixinlines"
  local inline_elements = settings.inline_elements or inline_elements
  local nodes = obj:get_path("html body")
  obj:traverse_node_list(nodes, function(jej) 
    if jej._type == "ELEMENT" then
      local name = string.lower(jej._name)
      -- local parent = jej:get_parent_node()
      if inline_elements[name] then
        local new = obj:create_element("p" )
        new:add_child_node(obj:copy_node(jej))
        jej:replace_node(new)
      end
    end
  end)
  return obj
end

return fix_inlines
