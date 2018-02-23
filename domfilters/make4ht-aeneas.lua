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

local task_template = [[
<task>
    <task_language>${lang}</task_language>
    <task_description>${file_desc}</task_description>
    <task_custom_id>${file_id}</task_custom_id>
    <is_text_file>${html_file}</is_text_file>
    <is_text_type>${text_type}</is_text_type>
    <is_audio_file>${audio_file}</is_audio_file>
    <os_task_file_name>${sub_file}</os_task_file_name>
    <os_task_file_format>${sub_format}</os_task_file_format>
    <os_task_file_smil_page_ref>${htmlfile}</os_task_file_smil_page_ref>
    <os_task_file_smil_audio_ref>${audiofile}</os_task_file_smil_audio_ref>
</task>
]]

-- get html files
local function get_html_files(config)
  local config = config or {}
  local files = {}
  local filematch = config.file_match or  "html$"
  -- this is a trick to get list of files from the LG file
  for _, file in ipairs(Make.lgfile.files) do
    if file:match(filematch) then table.insert(files, file) end
  end
  return files
end



-- create task record for each HTML file
local function prepare_tasks(files, configuration)
  local tasks = {}
  for _, filename in ipairs(files) do
    local taskconfig = configuration
    taskconfig.html_file = filename
    tasks[#tasks+1] = task_template % taskconfig
  end
  return table.concat(tasks, "\n")
end
-- from https://www.readbeyond.it/aeneas/docs/clitutorial.html#xml-config-file-config-xml
local config_template = [[
<job>
    <job_language>${lang}</job_language>
    <job_description>${description}</job_description>
    <tasks>
    ${tasks}
    </tasks>
    <os_job_file_name>output_example4</os_job_file_name>
    <os_job_file_container>zip</os_job_file_container>
    <os_job_file_hierarchy_type>flat</os_job_file_hierarchy_type>
    <os_job_file_hierarchy_prefix>OEBPS/Resources/</os_job_file_hierarchy_prefix>
</job>
]]

-- check if the config file exists
local function is_config(filename)
  return mkutils.file_exists(filename)
end

-- prepare Aeneas configuration
local function prepare_configuration(dom, parameters)
  local get_lang = function(d)
    local html = d:query_selector("html")[1] or {}
    return html:get_attribute("lang")
  end
  local config = parameters or {}
  config.lang = parameters.lang or  get_lang(dom)
  print(parameters.files)
  config.tasks = prepare_tasks(parameters.files, config)
  return config
end

-- write Aeneeas configuration file in the XML format
local function write_config(filename, configuration)
  print(config_template % configuration)
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

  -- configuration table for Aeneas job
  local configuration = {}
  configuration.description = options.description or par.description or "Aeneas job"
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
  -- write the configuration only if the config file doesn't exist
  if not is_config(config_name) then
    configuration.files = get_html_files()
    local configuration = prepare_configuration(dom, configuration)
    write_config(config_name, configuration)
  end
  return dom
end

return aeneas
