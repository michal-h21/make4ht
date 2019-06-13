local domobject = require "luaxml-domobject"

local filter = require "make4ht-filter"


local toc_levels = {"partToc", "chapterToc", "sectionToc", "subsectionToc", "subsubsectionToc"}

local debug_print  

if _debug then
  debug_print = print
else
  debug_print = function(s) end
end

-- return toc element type and it's id
local function get_id(el)
  local name =  el:get_attribute "class"
  local id
  local a = el:query_selector "a" or {}
  local first = a[1]
  if first then
    local href = first:get_attribute "href"
    id = href:match("#(.+)$")
  end
  return name, id
end

local function remove_sections(part_elements, currentpart)
  -- we need to remove toc entries from the previous part if the
  -- current document isn't part of it
  if currentpart == false then
    for _, part in ipairs(part_elements) do
      part:remove_node()
    end
  end
end

local function make_toc_selector(toc_levels)
  local level_classes = {}
  for _, l in ipairs(toc_levels) do
    level_classes[#level_classes+1] = "." .. l
  end
  return table.concat(level_classes, ", ")
end

local function find_toc_levels(toc)
  -- find toc levels used in the document
  -- it ecpects that sectioning levels appears in the TOC in the descending order
  local levels, used = {}, {}
  local level = 1 
  -- we still expect the standard class names
  local toc_selector = make_toc_selector(toc_levels)
  for _, el in ipairs(toc:query_selector(toc_selector)) do
    local class = el:get_attribute("class")
    if not used[class] then
      table.insert(levels, class)
      used[class] = level
      level = level + 1
    end
  end
  return levels, used
end

local function remove_levels(toc, matched_ids)
  -- sort the matched sections according to their levels
  local levels, level_numbers = find_toc_levels(toc)
  debug_print("remove levels", #levels)
  -- for _, level in ipairs(levels) do
  --   print(level, level_numbers[level], matched_ids[level])
  -- end
  local keep_branch = false
  local matched_levels = {}
  local toc_selector = make_toc_selector(toc_levels)
  for _, el in ipairs(toc:query_selector(toc_selector)) do
    local name, id = get_id(el)
    -- get the current toc hiearchy level
    local level = level_numbers[name]
    -- get the matched id for the current level
    local level_id = matched_ids[name]
    local matched = level_id == id
    local remove = true
    -- we will use this for toc elements at lower hiearchy than is the top sectioning level on the page
    if matched then keep_branch = true end
    -- find the parent level to the current section level
    local parent_level = toc_levels[level - 1]
    local parent_matched = matched_levels[parent_level]
    if matched then 
      debug_print("match",name, id, level_id, level, #levels)
      keep_branch = true
      remove = false
    elseif level==1 then 
      -- don't remove the top level 
      debug_print("part",name, id, level_id, level)
      remove = false
      matched_levels = {}
      if not matched then keep_branch = false end
    elseif keep_branch then 
      -- if level >= (#levels - 1) then
        if level > matched_ids._levels then
          debug_print("level",name, id, level_id, level, parent_level, parent_matched)
          remove = false
        elseif matched_ids.ids[id] then
          debug_print("matched id",name, id, level_id, level, parent_level, parent_matched)
          remove = false
        elseif parent_matched  then
          debug_print("parent_matched",name, id, level_id, level, parent_level, parent_matched)
          keep_branch = false
          remove = false
        end
      -- else
        -- print("remove", name, id, level_id, level, #matched_ids)
      -- end
    elseif parent_matched then
      debug_print("parent_matched alternative",name, id, level_id, level, parent_level, parent_matched)
      remove = false
    else
      debug_print("else",name, id, level_id, level, keep_branch)
      keep_branch = false
    end
    matched_levels[name] = matched
    if remove then
      el:remove_node()
      --print(name,id, level_id,  matched)
    end
  end
  
end





-- local process = filter{ function(s)
  -- local dom = domobject.parse(s)
local function collapse_toc(dom, par)
  -- set options
  local options = get_filter_settings "collapsetoc"
  local toc_query = par.toc_query or options.toc_query or ".tableofcontents"
  local title_query = par.title_query or options.title_query or ".partHead a, .chapterHead a, .sectionHead a, .subsectionHead a"
  toc_levels = par.toc_levels or options.toc_levels or toc_levels
  -- keep track of current id of each sectioning level
  local current_ids, matched_ids = {}, {_levels = 0, ids = {}}
  -- search sectioning elements
  local titles = dom:query_selector(title_query)
  local section_ids = {}
  for _, x in ipairs(titles) do
    -- get their id attributes and save them in a table
    section_ids[#section_ids+1] = x:get_attribute("id")
  end

  -- we need to retrieve the first table of contents
  local toctables = dom:query_selector(toc_query) or {}
  -- process only when we got a TOC
  debug_print("toc query", toc_query, #toctables)
  if #toctables > 0 then
    local tableofcontents = toctables[1]
    -- all toc entries are in span elements
    local toc = tableofcontents:query_selector("span")
    local currentpart = false
    local part_elements = {}
    for _, el in ipairs(toc) do
      -- get sectioning level and id of the current TOC entry
      local name, id = get_id(el)
      -- set the id of the current sectioning level
      current_ids[name] = id
      for _, sectid in ipairs(section_ids) do
        -- detect if the current TOC entry match some sectioning element in the current document
        if id == sectid then
          currentpart = true
          -- save the current id as a matched id
          matched_ids.ids[id] = true
          -- copy the TOC hiearchy for the current toc level
          for i, level in ipairs(toc_levels) do 
            -- print("xxx",i, level, current_ids[level])
            matched_ids[level] = current_ids[level]
            -- set the maximum matched level
            if i > matched_ids._levels then matched_ids._levels = i end
            if level == name then break end
          end
          debug_print("match", id)
        end
      end
    end
    remove_levels(tableofcontents, matched_ids)

    -- remove sections from the last part
    -- remove_sections(part_elements,currentpart)
    -- remove unneeded br elements
    local br = tableofcontents:query_selector("br")
    for _, el in ipairs(br) do el:remove_node() end
    -- remove unneded whitespace
    for _, el in ipairs(tableofcontents:get_children()) do
      if el:is_text() then el:remove_node() end
    end
  end
  return dom
end 

return collapse_toc

-- Make:match("html$", process)
