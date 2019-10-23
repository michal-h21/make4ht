-- preprocess R literate sources or Markdown files to LaTeX
local M = {}
local log = logging.new "preprocess_input"
local mkutils = require "mkutils"

local commands = {
  knitr = { command = 'Rscript -e "library(knitr); knit(\'${tex_file}\', output=\'${tmp_file}\')"'},
  pandoc = { command = 'pandoc -f ${input_format} -s -o \'${tmp_file}\' -t latex \'${tex_file}\''}
}
local filetypes = {
  rnw = {sequence = {"knitr"} },
  rtex = {sequence = {"knitr"}},
  rmd = {sequence = {"knitr", "pandoc"}, options = {input_format = "markdown"}},
  rrst = {sequence = {"knitr", "pandoc"}, options = {input_format = "rst"}},
  md = {sequence = {"pandoc"}, options = {input_format = "markdown"}},
  rst = {sequence = {"pandoc"}, options = {input_format = "rst"}},
}


local function execute_sequence(sequence, arg, make)
  -- keep track of all generated tmp files
  local temp_files = {}
  -- the temporary file for the current compilation step 
  -- should become the tex_file for the next one. It doesn't
  -- matter that it isn't TeX file in some cases
  local previous_temp 
  for _, cmd_name in ipairs(sequence) do
    local tmp_name = os.tmpname()
    temp_files[#temp_files+1] = tmp_name
    -- make the temp file name accessible to the executed commands
    arg.tmp_file = tmp_name
    -- the current temporary file should become tex_file in the next step
    -- in the first execution of the compilation sequence we will use the 
    -- actual input file name
    arg.tex_file = previous_temp or arg.tex_file
    previous_temp = tmp_name
    -- get the command to execute
    local cmd  = commands[cmd_name]
    -- fill the command template with make4ht arguments and execute
    local command = cmd.command % arg
    log:info(command)
    mkutils.execute(command)
  end
  return temp_files
end

local function get_preprocessing_pipeline(input_file)
    -- detect the file extension
    local extension = input_file:match("%.(.-)$")
    if not extension then return nil, "Cannot get extension: " .. input_file end
    -- the table with file actions is case insensitive
    -- the extension is converted to lowercase in order
    -- to support both .rnw and .Rnw
    extension = string.lower(extension)
    local matched = filetypes[extension]
    if not matched then return nil, "Unsupported extension: " .. extension end
    return matched
end

-- join the make4ht params and command options tables
local function make_options(arg, command_options)
  local options = {}
  local command_options = command_options or {}
  for k,v in pairs(arg) do options[k] = v end
  for k,v in pairs(command_options) do options[k] = v end
  return options
end

M.modify_build = function(make)

  -- get access to the main argumens
  local arg = make.params
  -- get the execution sequence for the input format
  local matched, msg  = get_preprocessing_pipeline(arg.tex_file)
  if not matched then 
    log:error("preprocess_input error: ".. msg)
    return
  end
  -- prepare options 
  local options = make_options(arg, matched.options)
  -- run the execution sequence
  local temp_files = execute_sequence(matched.sequence or {}, options, make)
  -- the last temporary file contains the actual TeX file
  local last_temp_file = temp_files[#temp_files]
  -- remove the intermediate temp files
  if #temp_files > 2 then
    for i = 1, #temp_files - 1 do
      log:debug("Removing temporary file", temp_files[i])
      os.remove(temp_files[i])
    end
  end
  if last_temp_file then
    -- update all commands in the .mk4 file with the temp file as tex_file
    local update_params = function(cmd)
      local params = cmd.params
      params.tex_file = last_temp_file
      params.is_tmp_file = true
    end
    for _, cmd in ipairs(make.build_seq) do
      update_params(cmd)
    end
    -- also update the main params
    update_params(make)
  end
  return make
end

return M
