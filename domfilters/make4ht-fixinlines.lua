local inline_elements = {
  a=true,
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
  local new = nil
  obj:traverse_node_list(nodes, function(jej) 
    if jej._type == "ELEMENT" or jej._type == "TEXT" then
      local name = string.lower(jej._name or "")
      -- local parent = jej:get_parent_node()
      if inline_elements[name] or jej._type == "TEXT" then
        if not new then
          -- start new paragraph
          if jej._type == "TEXT" and jej._text:match("^%s+$") then
            -- ignore parts that contain only whitespace and are placed before 
            -- paragraph start
          else
            new = obj:create_element("p" )
            new:add_child_node(obj:copy_node(jej))
            jej:replace_node(new)
          end
        else
          -- paragraph already exists
          new:add_child_node(obj:copy_node(jej))
          jej:remove_node()
        end
      else
        -- close the current paragraph before new block element
        new = nil
      end
    else
      new = nil
    end
  end)
  return obj
end

return fix_inlines
