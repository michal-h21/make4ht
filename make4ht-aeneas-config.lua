local M = {}

local mkutils = require "mkutils"

local task_template = [[
<task>
    <task_language>${lang}</task_language>
    <task_description>${file_desc}</task_description>
    <task_custom_id>${file_id}</task_custom_id>
    <is_text_file>${prefix}${html_file}</is_text_file>
    <is_text_type>${text_type}</is_text_type>
    <is_audio_file>${prefix}${audio_file}</is_audio_file>
    <is_text_unparsed_id_sort>${id_sort}</is_text_unparsed_id_sort>
    <is_text_unparsed_id_regex>${id_regex}</is_text_unparsed_id_regex>
    <os_task_file_name>${sub_file}</os_task_file_name>
    <os_task_file_format>${sub_format}</os_task_file_format>
    <os_task_file_smil_page_ref>${html_file}</os_task_file_smil_page_ref>
    <os_task_file_smil_audio_ref>${audio_file}</os_task_file_smil_audio_ref>
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

-- prepare filename for the audio
local function get_audio_file(filename, config)
  local extension = config.audio_extension or "mp3"
  local base = mkutils.remove_extension(filename)
  return base .. "." .. extension
end

local function get_sub_file(filename, config)
  local extension = config.sub_format or "smil"
  local base = mkutils.remove_extension(filename)
  return base .. "." .. extension
end


-- create task record for each HTML file
local function prepare_tasks(files, configuration)
  local tasks = {}
  --  the map can contain info for particular files, otherwise we will interfere default values
  local map = configuration.map or {}
  -- task_template should be configurable
  local task_template = configuration.task_template or task_template
  for i, filename in ipairs(files) do
    local filemap = map[filename] 
    if filemap ~= false then
      filemap = filemap or {}
      local taskconfig = configuration
      taskconfig.html_file = filename
      taskconfig.prefix = filemap.prefix or configuration.prefix
      taskconfig.file_desc = filemap.description or configuration.description .. " " .. i
      taskconfig.file_id = filemap.id or filename:gsub("[%/%.]", "_")
      taskconfig.text_type = filemap.text_type or configuration.text_type
      taskconfig.audio_file = filemap.audio_file or get_audio_file(filename, configuration)
      taskconfig.sub_file = filemap.sub_file or get_sub_file(filename, configuration)
      taskconfig.id_sort= filemap.id_sort  or configuration.id_sort
      taskconfig.id_prefix = filemap.id_regex or configuration.id_regex
      taskconfig.sub_format = filemap.sub_format or configuration.sub_format
      tasks[#tasks+1] = task_template % taskconfig
      Make:add_file(taskconfig.audio_file)
      Make:add_file(taskconfig.sub_file)
    end
  end
  return tasks --table.concat(tasks, "\n")
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
    <os_job_file_hierarchy_prefix>${prefix}</os_job_file_hierarchy_prefix>
</job>
]]

-- check if the config file exists
local function is_config(filename)
  return mkutils.file_exists(filename)
end

-- prepare Aeneas configuration
local function prepare_configuration(parameters)
  local config = parameters or {}
  config.lang = parameters.lang 
  config.tasks = table.concat(prepare_tasks(parameters.files, config), "\n")
  return config
end

-- write Aeneeas configuration file in the XML format
local function write_config(filename, configuration)
  local cfg = config_template % configuration
  print(cfg)
  local f = io.open(filename, "w")
  f:write(cfg)
  f:close()
end


local function make_default_options(options)
  local configuration = {}
  local par = get_filter_settings "aeneas-config"
  configuration.lang = options.lang or par.lang or "en"
  configuration.description = options.description or par.description or "Aeneas job"
  configuration.map = options.map or par.map or {}
  configuration.text_type = options.text_type or par.text_type or "unparsed"
  configuration.id_sort = options.id_sort or par.id_sort or "numeric"
  configuration.id_regex = options.id_regex or par.id_regex or par.id_prefix .. "[0-9]+"
  configuration.sub_format = options.sub_format or par.sub_format or "smil"
  configuration.prefix = options.prefix or par.prefix or "./"
  configuration.config_name = options.config_name or par.config_name or "config.xml"
  configuration.keep_config = options.keep_config or par.keep_config
  return configuration
end


local function configure_job(options)
  local configuration = make_default_options(options)
  local config_name = configuration.config_name
  -- prepare the configuration in every case
  configuration.files = get_html_files()
  local configuration = prepare_configuration(configuration)
  -- write the configuration only if the config file doesn't exist
  -- and keep_config option is set to true
  if is_config(config_name) and configuration.keep_config==true then
  else
    write_config(config_name, configuration)
  end
end

local function execute_job(options)
  local par = get_filter_settings "aeneas-config"
  local configuration = make_default_options(options)
  configuration.files = get_html_files()
  -- we need to configure prepare_tasks to return calls to aeneas task convertor
  configuration.python = options.python or par.python or "python3"
  configuration.module = options.module or par.module or "aeneas.tools.execute_task"
  configuration.task_template = '${python} -m "${module}" "${audio_file}" "${html_file}" "is_text_type=${text_type}|os_task_file_smil_audio_ref=${audio_file}|os_task_file_smil_page_ref=${html_file}|task_language=${lang}|is_text_unparsed_id_sort=${id_sort}|is_text_unparsed_id_regex=${id_regex}|os_task_file_format=${sub_format}" "${sub_file}"'
  local tasks = prepare_tasks(configuration.files, configuration)
  -- execute the tasks
  for _, v in ipairs(tasks) do
    print("task", v)
    local proc = io.popen(v, "r")
    local result = proc:read("*all")
    proc:close()
    print(result)
  end
end

-- the aeneas configuration must be executed at last processed file, after all filters
-- have been executed
local function get_last_lg_file()
  local t = Make.lgfile.files
  for i = #t, 1, -1 do
    --  find last html file or the tmp file
    local x = t[i]
    if x:match "html$" or x:match "tmp$" then 
      return x 
    end
  end
  return t[#t]
end

-- write Aeneas job configuration file
-- it doesn't execute Aeneas
function M.write_job(par)
  -- configuration table for Aeneas job
  Make:match("tmp$", function()
    configure_job(par)
  end)
end

-- execute Aeneas directly
function M.execute(par)
  Make:match("tmp$", function(current_name)
    -- there may be html files after the .tmp file
    -- the aeneas must be executed after the Aeneas filter inserts the id
    -- attributes, so it is necessary to execute this code as very last one
    local last = get_last_lg_file()
    -- execute the job if there are no HTML files after the tmp file
    if current_name == last then
      execute_job(par)
    end
    Make:match(last, function()
      execute_job(par)
    end)
  end)
end

-- only register the audio and smil files as processed files
function M.process_files(par)
  Make:match("tmp$", function()
    local configuration = make_default_options(par)
    local files = get_html_files()
    prepare_tasks(files, configuration)
  end)
end


return M
