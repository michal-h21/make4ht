
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
  config.tasks = prepare_tasks(parameters.files, config)
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

local function run(options)
  -- write the configuration only if the config file doesn't exist
  local configuration = par or {}
  local par = get_filter_settings "aeneas-config"
  configuration.lang = options.lang or par.lang or "en"
  configuration.description = options.description or par.description or "Aeneas job"
  configuration.map = options.map or par.map or {}
  configuration.text_type = options.text_type or par.text_type or "unparsed"
  configuration.id_sort = options.id_sort or par.id_sort or "numeric"
  configuration.id_regex = options.id_regex or par.id_regex or par.id_prefix .. "[0-9]+"
  configuration.sub_format = options.sub_format or par.sub_format or "smil"
  configuration.prefix = options.prefix or par.prefix or "./"
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
