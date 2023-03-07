local log = logging.new ("tablerows")
return function(dom)
  local has_child_elements = function(child)
    -- detect if the element contains child elements
    local child_elements = 0
    local children = child:get_children()
    local last_child_pos
    for pos, el in ipairs(children) do
      last_child_pos = pos
      local step = el:is_element() and 1 or 0
      -- log:info("element name", el._name)
      child_elements = child_elements + step
    end
    -- longtable has <td><p></p></td> inside empty rows, we regard them as empty
    if child_elements == 1 and children[last_child_pos]:get_element_name() == "p" and child:get_text():gsub("%s", "") == "" then
      child_elements = 0
    end
    return child_elements > 0
  end
  local is_empty_row = function(row)
    local not_empty = false
    local element_count = 0
    -- ignore hline rows
    local row_class = row:get_attribute("class") 
    if row_class == "hline" or row_class == "cline" then return false end
    -- detect if the row contain only one empty child
    for _,child in ipairs(row:get_children() or {}) do
      if child:is_element() then 
        element_count = element_count + 1
        -- empty rows contain only one element, it is not empty otherwise
        if element_count > 1 or has_child_elements(child) then return false end

        -- detect if it contains only whitespace
        not_empty = child:get_text():gsub("%s","") ~= "" or not_empty
      end
    end
    -- print("element count", element_count, not_empty)
    return element_count == 1 and not_empty == false
  end
  local is_not_styled = function(row, css)
    -- get the id attribute and escape it, so it can be used in regexp
    local id = row:get_attribute("id")
    if not id then return true end -- no styling without id
    local search_term = "%#" .. id:gsub("%-", "%%-")
    -- if the CSS file contains the row id (<td> elements can also have id
    -- that matches this pattern, so we should keep the row if we match them too)
    return not css:match(search_term)
  end
  local hline_hr = function(row)
    -- remove <hr> elements from "hline" rows
    for _, hr in ipairs(row:query_selector(".hline hr")) do
      hr:remove_node()
    end
  end
  local load_css_files = function()
    -- the empty rows can be styled using CSS, for example configuration for 
    -- Booktabs does that. We shouldn't remove such rows.
    local cssfiles = {}
    for  _, link in ipairs(dom:query_selector("head link")) do
      local src = link:get_attribute("href")
      if src then
        local f = io.open(src, "r")
        if f then
          local contents = f:read("*all")
          f:close()
          table.insert(cssfiles, contents)
        end
      end
    end
    return table.concat(cssfiles, "\n")
  end
  local css = load_css_files()
  for _, tbl in ipairs(dom:query_selector("table")) do
    -- find the empty rows
    for _, row in ipairs(tbl:query_selector("tr")) do
      if is_empty_row(row) and is_not_styled(row, css) then row:remove_node() end
      hline_hr(row)
    end

  end
  return dom
end

