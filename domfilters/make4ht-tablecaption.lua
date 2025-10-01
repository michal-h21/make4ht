local function get_parent_table(caption)
  -- recursively find the parent table of a caption element, as it can be inside <tr> and <td>
  local parent = caption:get_parent()
  if parent and parent:get_element_name() == "table" then
    return parent
  elseif parent then
    return get_parent_table(parent)
  else
    return nil
  end
end

return function(dom)
  -- the caption element must be a first element in table, it cannot be contained inside tr
  for _, caption in ipairs(dom:query_selector("table caption")) do
    local table = get_parent_table(caption)
    if table then
      -- insert caption as the first child of table
      table:add_child_node(caption:copy_node(),1)
      -- remove the original caption
      caption:remove_node()
    end
  end
  return dom
end
