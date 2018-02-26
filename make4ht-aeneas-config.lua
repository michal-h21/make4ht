
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
local function prepare_configuration(parameters)
  local config = parameters or {}
  config.lang = parameters.lang 
  print(parameters.files)
  config.tasks = prepare_tasks(parameters.files, config)
  return config
end

-- write Aeneeas configuration file in the XML format
local function write_config(filename, configuration)
  print(config_template % configuration)
end

local function run(options)
  -- write the configuration only if the config file doesn't exist
  local configuration = par or {}
  local par = get_filter_settings "aeneas-config"
  configuration.lang = options.lang or par.lang or "en"
  configuration.description = options.description or par.description or "Aeneas job"
  local config_name = options.config_name or par.config_name or "config.xml"
  if not is_config(config_name) then
    configuration.files = get_html_files()
    local configuration = prepare_configuration(configuration)
    write_config(config_name, configuration)
  end
end



local function aeneas_config(par)
  -- configuration table for Aeneas job
  Make:match("tmp$", function()
    run(par)
  end)
end

return aeneas_config
