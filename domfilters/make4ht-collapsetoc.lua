-- mini TOC support for make4ht
local domobject = require "luaxml-domobject"

local filter = require "make4ht-filter"
local log = logging.new "collapsetoc"
local mktuils = require "mkutils"


-- assign levels to entries in the .4tc file
local toc_levels = {
  tocpart = 1,
  toclikepart = 1,
  tocappendix = 2,
  toclikechapter = 2,
  tocchapter = 2,
  tocsection = 3,
  toclikesection = 3,
  tocsubsection = 4,
  toclikesubsection = 4,
  tocsubsubsection = 5,
  toclikesubsubsection = 5,
  tocparagraph = 6,
  toclikeparagraph = 6,
  tocsubparagraph = 7,
  toclikesubparagraph = 7,
}

-- number of child levels to be kept
-- the depth of 1 ensures that only direct children of the current sectioning command 
-- will be kept in TOC
local max_depth = 1


-- debugging function to test correct structure of the TOC tree
local function print_tree(tree, level) 
  local level = level or 0
  log:debug(string.rep(" ", level) .. (tree.type or "root"), tree.id)
  for k, v in pairs(tree.children) do
    print_tree(v, level + 2)
  end
end

-- convert the parsed toc entries to a tree structure
local function make_toc_tree(tocentries, lowestlevel, position, tree)
  local position = position or 1
  local tree = tree or {
    level = lowestlevel - 1,
    children = {}
  }
  local stack = {tree}
  if position > #tocentries then return tree, position end
  -- loop over TOC entries and make a tree
  for i = 1, #tocentries do
    -- initialize new child
    local element = tocentries[i]
    element.children = element.children or {}
    local parent = stack[#stack]
    local level_diff = element.level - parent.level
    if level_diff == 0 then -- entry is sibling of parent
      -- current parent is sibling of the current elemetn, true parent is 
      -- sibling's parent
      parent = parent.parent
      -- we must replace sibling element with the current element in stact
      -- so the child elements get correct parent
      table.remove(stack)
      table.insert(stack, element)
    elseif level_diff > 0 then -- entry is child of parent
      for x = 1, level_diff do
        table.insert(stack, element)
      end
    else
      -- we must remove levels from the stack to get the correct parent
      for x =1 , level_diff, -1 do
        if #stack > 0 then
          parent = table.remove(stack)
        end
      end
      -- we must reinsert parent back to stack, place the current element to stact too
      table.insert(stack, parent)
      table.insert(stack, element)
    end
    table.insert(parent.children, element)
    element.parent = parent
  end
  print_tree(tree)
  return tree
end

-- find first sectioning element in the current page
local function find_headers(dom, header_levels)
  -- we need to find id attributes in <a> elements that are children of sectioning elements
  local ids = {}
  for _, header in ipairs(dom:query_selector(header_levels)) do
    local id = header:get_attribute "id"
    if id then ids[#ids+1] = id end
  end
  return ids
end


-- process list of ids and find those that should be kept:
-- siblings, children, parents and top level
local function find_toc_entries_to_keep(ids, tree)
  local tree = tree or {}
  -- all id in TOC tree that we want to kepp are saved in this table
  local ids_to_keep = {}
  -- find current id in the TOC tree
  local function find_id(id, tree)
    if tree.id == id then return tree end
    if not tree.children or #tree.children == 0 then return false end
    for k,v in pairs(tree.children) do
      local found_id = find_id(id, v)
      if found_id then return found_id end
    end
    return false
  end
  -- always keep top level of the hiearchy
  local function keep_toplevel(tree)
    for _, el in ipairs(tree.children) do
      ids_to_keep[el.id] = true
    end
  end
  -- we want to keep all children in TOC hiearchy
  local function keep_children(element, depth)
    local depth = depth or 1
    local max_depth = max_depth or 1
    -- stop processing when there are no children
    for _, el in pairs(element.children or {}) do
      if el.id then ids_to_keep[el.id] = true end
      -- by default, we keep just direct children of the current sectioning element
      if depth < max_depth then
        keep_children(el, depth + 1)
      end
    end
  end
  -- also keep all siblings
  local function keep_siblings(element)
    local parent = element.parent
    for k, v in pairs(parent.children or {}) do
      ids_to_keep[v.id] = true
    end
  end
  -- and of course, keep all parents
  local function keep_parents(element)
    local parent = element.parent
    if parent and parent.id then
      ids_to_keep[parent.id] = true
      -- we should keep siblings of all parents as well
      keep_siblings(parent)
      keep_parents(parent)
    end
  end
  -- always keep the top-level TOC hiearchy, even if we cannot find any sectioning element on the page
  keep_toplevel(tree)
  for _, id in ipairs(ids) do
    -- keep the current id
    ids_to_keep[id] = true
    local found_element = find_id(id, tree)
    if found_element then
      keep_children(found_element)
      keep_siblings(found_element)
      keep_parents(found_element)
    end
  end
  return ids_to_keep
end

-- process the .4tc file and convert entries to a tree structure
-- based on the sectioning level
local function parse_4tc(parameters, toc_levels)
  local tcfilename = mkutils.file_in_builddir(parameters.input .. ".4tc", parameters)
  if not mkutils.file_exists(tcfilename) then 
    log:warning("Cannot find TOC: " .. tcfilename)
    return {}
  end
  local tocentries = {}
  local f = io.open(tcfilename, "r")
  -- we need to find the lowest level used in the TOC
  local lowestlevel = 999
  for line in f:lines() do
    -- entries looks like: \doTocEntry\tocsubsection{1.2.2}{\csname a:TocLink\endcsname{5}{x5-60001.2.2}{QQ2-5-6}{aaaa}}{7}\relax 
    -- we want do extract tocsubsection and x5-60001.2.2
    local toctype, id = line:match("\\doTocEntry\\(.-){.-}{.-{.-}{(.-)}")
    if toctype then
      local level = toc_levels[toctype]
      if not level then 
        log:warning("Cannot find TOC level for: " .. toctype)
      else
        lowestlevel = level < lowestlevel and level or lowestlevel
        table.insert(tocentries, {type = toctype, id = id, level = level})
      end
    end
  end
  f:close()
  local toc =  make_toc_tree(tocentries, lowestlevel)
  return toc
end

local function remove_levels(toc, matched_ids)
  -- remove links that aren't in the TOC hiearchy that should be kept
  for _, link in ipairs(toc:query_selector("a")) do
    local href = link:get_attribute("href")
    -- find id in the href
    local id = href:match("#(.+)")
    if id and not matched_ids[id] then
      -- toc links are in <span> elements that can contain the section number
      -- we must remove them too
      local parent = link:get_parent()
      if parent:get_element_name() == "span" then
        parent:remove_node()
      else
        -- if the parent node isn't <span>, remove at least the link itself
        link:remove_node()
      end
    end
  end
end


local function collapsetoc(dom, parameters)
  -- set options
  local par = parameters
  local options = get_filter_settings "collapsetoc"
  -- query to find the TOC element in DOM
  local toc_query = par.toc_query or options.toc_query or ".tableofcontents"
  -- query to select sectioning elements with id's
  local title_query = par.title_query or options.title_query or "h1 a, h2 a, h3 a, h4 a, h5 a, h6 a" 
  -- level of child levels to be kept in TOC
  max_depth = par.max_depth or options.max_depth or max_depth
  -- set level numbers for particular TOC entry types
  local user_toc_levels = par.toc_levels or options.toc_levels or {}
  -- join user's levels with default
  for k,v in pairs(user_toc_levels) do toc_levels[k] = v end
  -- parse the .4tc file to get TOC tree
  toc = toc or parse_4tc(parameters, toc_levels)
  -- find sections in the current html file
  local ids = find_headers(dom, title_query)
  log:debug("Ids", table.concat(ids, ","))
  local ids_to_keep = find_toc_entries_to_keep(ids, toc)
  local toc_dom = dom:query_selector(toc_query)[1]
  if toc_dom then
    remove_levels(toc_dom, ids_to_keep)
  else
    log:warning("Cannot find TOC element using query: " .. toc_query)
  end
  return dom
end

return collapsetoc
