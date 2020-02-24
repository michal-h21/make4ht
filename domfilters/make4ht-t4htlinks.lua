-- This filter is used by the ODT output format to fix links
return  function(dom)
  for _, link in ipairs(dom:query_selector("t4htlink")) do
    local name = link:get_attribute("name")
    local href = link:get_attribute("href")
    local children = link:get_children()
    -- print("link", name, href, #link._children, link:get_text())
    -- add a link if it contains any subnodes and has href attribute
    if #children > 0 and href then
      link._name = "text:a"
      href = href:gsub("^.+4oo%#", "#")
      link._attr = {["xlink:type"]="simple", ["xlink:href"]=href}
      -- if the link is named, add a bookmark
      if name then
        local bookmark = link:create_element("text:bookmark", {["text:name"] = name})
        link:add_child_node(bookmark)
      end
      -- add bookmark if element has name 
    elseif name then
      link._name = "text:bookmark"
      link._attr = {["text:name"] = name}
    else
      -- just remove the link in other cases
      link:remove_node()
    end
  end
  return dom
end
