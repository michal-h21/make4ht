
local function has_cmidrule(td)
  -- detect if <td> contains <span> with a cmidrule class
  local children = td:get_children()
  if #children > 3 then return false end
  for _, child in ipairs(children) do
    if child:get_element_name() == "span" then
      if child:get_attribute("class") == "cmidrule" then
        return true
      end
    end
  end
  return false

end
local function find_cmidrules(current_rows)
  -- save rows with cmidrules here
  local matched_rows = {}
  local continue = false
  for row_no, row in ipairs(current_rows) do
    local columnposition = 1
    local matched_cmidrule = false

    for _, col in ipairs(row._children) do
      if col:get_element_name() == "td" then
        -- keep track of culumns
        local span = tonumber(col:get_attribute("colspan")) or 1
        -- column contain cmidrule
        if has_cmidrule(col) then
          -- remove any child elements, we don't need them anymore
          col._children = {}
          -- only one cmidrule can be on each row, save the position, column span and all attributes
          matched_rows[row_no] = {attributes = col._attr, column = columnposition, span = span, continue = continue}
          matched_cmidrule = true
        end
        columnposition = columnposition + span
      end
      if matched_cmidrule then
        -- save the row number of the first cmidrule on the current row
        continue = continue or row_no
      else
        continue = false
      end
    end

  end
  -- save the table rows count, so we can loop over them sequentially later
  matched_rows.length = #current_rows
  return matched_rows
end

local function update_row(current_rows, match, newspan, i)
  local row_to_update = current_rows[match.continue]
  -- insert spanning column if necessary
  if newspan > 0 then
    local td = row_to_update:create_element("td", {colspan=tostring(newspan), span="nazdar"})
    row_to_update:add_child_node(td)
  end
  -- insert the rule column
  local td = row_to_update:create_element("td", match.attributes)
  row_to_update:add_child_node(td)
  -- remove unnecessary row
  current_rows[i]:remove_node()
end

local function join_rows(matched_rows,current_rows)
  for i = 1, matched_rows.length do
    local match = matched_rows[i]
    if match then
      -- we only need to process rows that place subsequent cmidrules on the same row
      local continue = match.continue
      if continue then
        local prev_row = matched_rows[continue]
        -- find column where the previous cmidrule ends
        local prev_end = prev_row.column + prev_row.span
        local newspan = match.column - prev_end 
        update_row(current_rows, match, newspan, i)
        -- update the current row position
        prev_row.column = match.column
        prev_row.span = match.span
      end
    end
  end
end

local function process_booktabs(dom)
  local tables = dom:query_selector("table")
  for _, tbl in ipairs(tables) do
    local current_rows = tbl:query_selector("table > tr")
    local matched_rows = find_cmidrules(current_rows)
    join_rows(matched_rows, current_rows)
  end
  return dom
end

return process_booktabs

