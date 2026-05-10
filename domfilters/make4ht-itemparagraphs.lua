-- TeX4ht puts contents of all \item commands into paragraphs. We are not
-- able to detect if it contain only one paragraph, or more. If just one,
-- we can remove the paragraph and put the contents directly to <li> element.
return function(dom)
  for _, li in ipairs(dom:query_selector("li")) do
    local is_single_par = false
    -- count elements and paragraphs that are direct children of <li>
    -- remove the paragraph only if it is the only child element
    local el_count, par_count = 0, 0
    local par = {}
    for pos, el in ipairs(li._children) do
      if el:is_element() then
        el_count = el_count + 1
        local name = el:get_element_name()
        if name == "p" then
          par[#par+1] = el
        elseif name == "a" and el_count == 1 and el:get_attribute("id") then
          -- if the first element is <a> with id, we can move it to <li> and remove it from the list of children, this is needed for nested lists
          el_count = el_count - 1
          local id = el:get_attribute("id")
          if not li:get_attribute("id") then
            li:set_attribute("id", id)
            el:remove_node()
          end
        end
      end
    end
    if #par == 1 and el_count == 1 then
      -- place paragraph children as direct children of <li>, this
      -- efectivelly removes <p>
      li._children = par[1]._children
    end
  end
  return dom
end
