-- DOM filter for Aeneas, tool for automatical text and audio synchronization
-- https://github.com/readbeyond/aeneas
-- It adds elements with id attributes for text chunks, in sentence length.
--
--
local cssquery = require "luaxml-cssquery"
local mkutils  = require "mkutils"

-- Table of CSS selectors to be skipped.
local skip_elements = { "math", "svg"}

-- The id attribute format is configurable
-- Aeneas must be told to search for the ID pattern using is_text_unparsed_id_regex
-- option in Aneas configuration file
local id_prefix = "ast"

-- Pattern to mach a sentence. It should match two groups, first is actual
-- sentence, the second optional interpunction mark.
local sentence_match = "([^%.^%?^!]*)([%.%?!]?)"

-- convert table with selectors to a query list
local function prepare_selectors(skips)
  local css = cssquery()
  for _, selector in ipairs(skips) do
    css:add_selector(selector)
  end
  return css
end

-- make span element with unique id for a sentence
local function make_span(id,parent, text)
  local newobj = parent:create_element("span", {id=id }) 
  newobj.processed = true -- to disable multiple processing of the node
  local text_node = newobj:create_text_node(text)
  newobj:add_child_node(text_node)
  return newobj
end

-- make the id attribute and update the id value
local function make_id(lastid, id_prefix)
  local id = id_prefix .. lastid
  lastid = lastid + 1
  return id, lastid
end

-- parse text for sentences and add spans 
local function make_ids(parent, text, lastid, id_prefix)
  local t = {}
  local id
  for chunk, punct in text:gmatch(sentence_match) do
    id, lastid = make_id(lastid, id_prefix)
    local newtext = chunk..punct
    -- the newtext is empty string sometimes. we can skipt it then.
    if newtext~="" then
      table.insert(t, make_span(id, parent, newtext))
    end
  end
  return t, lastid
end

-- test if the DOM element is in list of skipped CSS selectors
local function is_skipped(el, css)
  local matched = css:match_querylist(el)
  return #matched > 0
end

-- from https://www.readbeyond.it/aeneas/docs/clitutorial.html#xml-config-file-config-xml
local config_template = [[
<job>
    <job_language>${lang}</job_language>
    <job_description>${description}</job_description>
    <tasks>
        <task>
            <task_language>en</task_language>
            <task_description>Sonnet 1</task_description>
            <task_custom_id>sonnet001</task_custom_id>
            <is_text_file>OEBPS/Resources/sonnet001.txt</is_text_file>
            <is_text_type>parsed</is_text_type>
            <is_audio_file>OEBPS/Resources/sonnet001.mp3</is_audio_file>
            <os_task_file_name>sonnet001.smil</os_task_file_name>
            <os_task_file_format>smil</os_task_file_format>
            <os_task_file_smil_page_ref>sonnet001.xhtml</os_task_file_smil_page_ref>
            <os_task_file_smil_audio_ref>sonnet001.mp3</os_task_file_smil_audio_ref>
        </task>
        <task>
            <task_language>en</task_language>
            <task_description>Sonnet 2</task_description>
            <task_custom_id>sonnet002</task_custom_id>
            <is_text_file>OEBPS/Resources/sonnet002.txt</is_text_file>
            <is_text_type>parsed</is_text_type>
            <is_audio_file>OEBPS/Resources/sonnet002.mp3</is_audio_file>
            <os_task_file_name>sonnet002.smil</os_task_file_name>
            <os_task_file_format>smil</os_task_file_format>
            <os_task_file_smil_page_ref>sonnet002.xhtml</os_task_file_smil_page_ref>
            <os_task_file_smil_audio_ref>sonnet002.mp3</os_task_file_smil_audio_ref>
        </task>
        <task>
            <task_language>en</task_language>
            <task_description>Sonnet 3</task_description>
            <task_custom_id>sonnet003</task_custom_id>
            <is_text_file>OEBPS/Resources/sonnet003.txt</is_text_file>
            <is_text_type>parsed</is_text_type>
            <is_audio_file>OEBPS/Resources/sonnet003.mp3</is_audio_file>
            <os_task_file_name>sonnet003.smil</os_task_file_name>
            <os_task_file_format>smil</os_task_file_format>
            <os_task_file_smil_page_ref>sonnet003.xhtml</os_task_file_smil_page_ref>
            <os_task_file_smil_audio_ref>sonnet003.mp3</os_task_file_smil_audio_ref>
        </task>
    </tasks>
    <os_job_file_name>output_example4</os_job_file_name>
    <os_job_file_container>zip</os_job_file_container>
    <os_job_file_hierarchy_type>flat</os_job_file_hierarchy_type>
    <os_job_file_hierarchy_prefix>OEBPS/Resources/</os_job_file_hierarchy_prefix>
</job>
]]
-- write Aeneeas configuration file in the XML format
local function write_config(filename, configuration)
  if not mkutils.file_exists(filename) then
    print(config_template % configuration)
  end
end


local function aeneas(dom, par)
  local par = par or {}
  local id = 1
  local options = get_filter_settings "aeneas"
  local skip_elements = options.skip_elements or par.skip_elements or skip_elements
  local id_prefix = options.id_prefix or par.id_prefix or id_prefix
  local skip_object = prepare_selectors(skip_elements)
  local config_name = options.config_name or par.config_name or "config.xml"
  sentence_match = options.sentence_match or par.sentence_match or sentence_match
  local body = dom:query_selector("body")[1]
  -- process only the document body
  if not body then return dom end
  body:traverse_elements(function(el)
    -- skip disabled elements
    if(is_skipped(el, skip_object)) then return false end
    -- skip already processed elements
    if el.processed then return false end
    local newchildren = {} -- this will contain the new elements
    local children = el:get_children()
    local first_child = children[1]

    -- if the element contains only text, doesn't already have an id attribute and the text is short,
    -- the id is set directly on that element.
    if #children == 1
      and first_child:is_text()
      and not el:get_attribute("id")
      and string.len(first_child._text) < 20
    then
      local idtitle
      idtitle, id = make_id(id, id_prefix)
      el:set_attribute("id", idtitle)
      return el
    end

    for _, child in ipairs(children) do
      -- process only non-empty text
      if child:is_text() and child._text:match("%a+") then
        local newnodes
        newnodes, id = make_ids(child, child._text, id, id_prefix)
        for _, node in ipairs(newnodes) do
          table.insert(newchildren, node or {})
        end
      else
        -- insert the current processing element to the new element list
        -- if it isn't only text
        table.insert(newchildren, child or {})
      end
    end
    -- replace element children with the new ones
    if #newchildren > 0 then
      el._children = {}
      for _, c in ipairs(newchildren) do
        el:add_child_node(c)
      end
    end
  end)
  write_config(config_name, configuration)
  return dom
end

return aeneas
