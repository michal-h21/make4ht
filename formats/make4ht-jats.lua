local M = {}
local xtpipeslib = require "make4ht-xtpipes"
local domfilter = require "make4ht-domfilter"


-- some elements need to be moved from the document flow to the document meta
local article_meta 
local elements_to_move_to_meta = {}
local function move_to_meta(el)
  -- we don't move elements immediatelly, because it would prevent them from further 
  -- processing in the filter. so we save them in an array, and move them once 
  -- the full DOM was processed
  table.insert(elements_to_move_to_meta, el)
end

local elements_to_move_to_title = {}
local function move_to_title_group(el)
  -- there can be only one title and subtitle
  local name = el:get_element_name()
  if not elements_to_move_to_title[name] then
    elements_to_move_to_title[name] = el
  end
end

local elements_to_move_to_contribs = {}
local function move_to_contribs(el)
  table.insert(elements_to_move_to_contribs, el)
end



local function process_moves()
  if article_meta then
    if elements_to_move_to_title["article-title"] 
      and #article_meta:query_selector("title-group") == 0 then -- don't move anything if user added title-group from a config file
      local title_group = article_meta:create_element("title-group")
      for _, name in ipairs{ "article-title", "subtitle" } do
        local v = elements_to_move_to_title[name] 
        if v then
          title_group:add_child_node(v:copy_node())
          v:remove_node()
        end
      end
      article_meta:add_child_node(title_group, 1)
    end
    if #elements_to_move_to_contribs > 0 then
      local contrib_group = article_meta:create_element("contrib-group")
      for _, el in ipairs(elements_to_move_to_contribs) do
        contrib_group:add_child_node(el:copy_node())
        el:remove_node()
      end
      article_meta:add_child_node(contrib_group)
    end
    for _, el in ipairs(elements_to_move_to_meta) do
      -- move elemnt's copy, and remove the original
      article_meta:add_child_node(el:copy_node())
      el:remove_node()
    end
  end
end

local function has_no_text(el)
  -- detect if element contains only whitespace
  if el:get_text():match("^%s*$") then
    --- if it contains any elements, it has text
    for _, child in ipairs(el:get_children()) do
      if child:is_element() then return false end
    end
    return true
  end
  return false
end

local function is_xref_id(el)
  return el:get_element_name() == "xref" and el:get_attribute("id") and el:get_attribute("rid") == nil and has_no_text(el)
end
-- set id to parent element for <xref> that contain only id
local function xref_to_id(el)
  local parent = el:get_parent()
  -- set id only if it doesn't exist yet
  if parent:get_attribute("id") == nil then
    parent:set_attribute("id", el:get_attribute("id"))
    el:remove_node()
  end
end

local function make_text(el)
  local text = el:get_text():gsub("^%s*", ""):gsub("%s*$", "")
  local text_el = el:create_text_node(text)
  el._children = {text_el}
end

local function is_empty_par(el)
  return el:get_element_name() == "p" and has_no_text(el)
end

local function handle_links(el, params)
  -- we must distinguish between internal links in the document, and external links
  -- to websites etc. these needs to be changed to the <ext-link> element.
  local link = el:get_attribute("rid") 
  if link then
    -- try to remove \jobname.xml from the beginning of the link
    -- if the rest starts with #, then it is an internal link
    local local_link = link:gsub("^" .. params.input .. ".xml", "")
    if local_link:match("^%#") then
      el:set_attribute("rid", local_link)
    else
      -- change element to ext-link for extenal links
      el._name = "ext-link"
      el:set_attribute("rid", nil)
      el:set_attribute("xlink:href", link)
    end
  end
end

local function handle_maketitle(el)
  -- <maketitle> is special element produced by TeX4ht from LaTeX's \maketitle
  -- we need to pick interesting info from there, and move it to the header
  local function is_empty(selector)
    return #article_meta:query_selector(selector) == 0
  end
  -- move <aff> to <contrib>
  local affiliations = {}
  for _, aff in ipairs(el:query_selector("aff")) do
    local id = aff:get_attribute("id") 
    if id then 
      for _,mark in ipairs(aff:query_selector("affmark")) do mark:remove_node() end
      affiliations[id] = aff:copy_node() 
    end
  end
  if is_empty("contrib") then
    for _, contrib in ipairs(el:query_selector("contrib")) do
      for _, affref in ipairs(contrib:query_selector("affref")) do
        local id = affref:get_attribute("rid") or ""
        -- we no longer need this node
        affref:remove_node()
        local linked_affiliation = affiliations[id]
        if linked_affiliation then
          contrib:add_child_node(linked_affiliation)
        end
      end
      for _, string_name in ipairs(contrib:query_selector("string-name")) do
        make_text(string_name)
      end
      move_to_contribs(contrib:copy_node())
      -- we need to remove it from here, even though we remove <maketitle> later
      -- we got doubgle contributors without that
      contrib:remove_node()
    end
  end
  if is_empty("pub-date") then
    for _, date in ipairs(el:query_selector("date")) do
      date._name = "pub-date"
      for _, s in ipairs(date:query_selector("string-date")) do
        make_text(s)
      end
      move_to_meta(date:copy_node())
    end
  end
  el:remove_node()
end





function M.prepare_parameters(settings, extensions)
  settings.tex4ht_sty_par = settings.tex4ht_sty_par ..",jats"
  settings = mkutils.extensions_prepare_parameters(extensions, settings)
  return settings
end

function M.prepare_extensions(extensions)
  return extensions
end

function M.modify_build(make)
  filter_settings("joincharacters", {charclasses = {italic=true, bold=true}})

  local process =  domfilter {
    function(dom, params)
      dom:traverse_elements(function(el)
        -- some elements need special treatment
        local el_name = el:get_element_name()
        if is_xref_id(el) then
          xref_to_id(el)
        elseif el_name == "article-meta" then
          -- save article-meta element for further processig
          article_meta = el
        elseif el_name == "article-title" then
          move_to_title_group(el)
        elseif el_name == "subtitle" then
          move_to_title_group(el)
        elseif el_name == "abstract" then
          move_to_meta(el)
        elseif el_name == "string-name" then
          make_text(el)
        elseif el_name == "contrib" then
          move_to_contribs(el)
        elseif is_empty_par(el) then
          -- remove empty paragraphs
          el:remove_node()
        elseif el_name == "xref" then
          handle_links(el, params)
        elseif el_name == "maketitle" then
          handle_maketitle(el)
        elseif el_name == "div" and el:get_attribute("class") == "maketitle" then
          el:remove_node()
        end

      end)
      -- move elements that are marked for move
      process_moves()
      return dom
    end, "joincharacters","mathmlfixes", "tablerows","booktabs"
  }
  local charclasses = {["mml:mi"] = true, ["mml:mn"] = true , italic = true, bold=true, roman = true, ["mml:mtext"] = true, mi=true, mn=true}
  make:match("xml$", process, {charclasses = charclasses})
  return make
end

return M
