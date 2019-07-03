-- find all tables inside paragraphs, replace the found paragraphs with the child table
return function(dom)
  for _,table in ipairs(dom:query_selector("text|p table|table")) do
    -- replace the paragraph by its child element
    local parent = table:get_parent() 
    parent:replace_node(table)
  end
  return dom
end
