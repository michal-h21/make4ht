local M = {}
local filter = require "make4ht-filter"
local mkutils = require "mkutils"
local log = logging.new "staticsite"

-- get the published file name
local function get_slug(settings)
  local published_name = mkutils.remove_extension(settings.tex_file) .. ".published"
  local config = get_filter_settings "staticsite"
  local file_pattern = config.file_pattern or "%Y-%m-%d-${input}"
  local time = os.time()

  -- we must save the published date, so the subsequent compilations at different days
  -- use the same name
  if mkutils.file_exists(published_name) then
    local f = io.open(published_name, "r")
    local readtime  = f:read("*line")
    time = tonumber(readtime)
    log:info("Already pubslished", slug)
    f:close()
  else
    -- escape 
    -- slug must contain the unescaped input name
    local f = io.open(published_name, "w")
    f:write(time)
    f:close()
  end
  -- set the updated and publishing times
  local updated
  -- the updated time will be set only when it is more than one day from the published time
  local newtime = os.time()
  if (newtime - time) > (24 * 3600) then updated = newtime end
  filter_settings "staticsite" {
    header = {
      time = time,
      updated = updated
    }
  }

  -- make the output file name in the format YYYY-MM-DD-old-filename.html
  local slug = os.date(file_pattern,time) % settings
  return slug
end


-- it is necessary to set correct -jobname in latex_par parameters field
-- in order to the get correct HTML file name
local function update_jobname(slug, latex_par)
  local latex_par = latex_par or ""
  if latex_par:match("%-jobname") then
    local firstchar=latex_par:match("%-jobname=.")
    local replace_pattern="%-jobname=[^%s]+"
    if firstchar == "'" or firstchar=='"' then
      replace_pattern = "%-jobname=".. firstchar .."[^%"..firstchar.."]+"
    end
    
    return latex_par:gsub(replace_pattern, "-jobname=".. slug)
  else
    return latex_par .. "-jobname="..slug
  end
end

-- execute the function passed as parameter only once, when the file matching
-- starts
local function insert_filter(make, pattern, fn)
  local insert_executed = false
  table.insert(make.matches, 1, {
    pattern=pattern,
    params = {},
    command = function()
      if not insert_executed  then
        fn()
      end
      insert_executed = true
    end
  })
end


local function copy_files(filename, par)
  local function prepare_path(dir, subdir)
    local path = dir .. "/" .. subdir .. "/" .. filename
    return path:gsub("//", "/")
  end
  -- get extension settings
  local site_settings = get_filter_settings "staticsite"
  local site_root = site_settings.site_root
  local map = site_settings.map or {}
  -- default path without subdir, will be used if the file is not matched
  -- by any pattern in the map
  local path = prepare_path(site_root, "")
  for pattern, destination in pairs(map) do
    if filename:match(pattern) then
      path = prepare_path(site_root, destination)
      break
    end
  end
  -- it is possible to use string extrapolation in path, for example for slug
  mkutils.copy(filename, path % par)
end

function M.modify_build(make)
  -- it is necessary to insert the filters for YAML header and file copying as last matches
  -- we use an bogus match which will be executed only once as the very first one to insert
  -- the filters
  -- I should make filter from this
  local process = filter {
    "staticsite"
  }
  local settings = make.params
  -- get the published file name
  local slug = get_slug(settings)
  for _, cmd in ipairs(make.build_seq) do
    -- all commands must use the published file name
    cmd.params.input = slug
    cmd.params.latex_par = update_jobname(slug, cmd.params.latex_par)
  end

  local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
  local mainfile = string.gsub(slug, quotepattern, "%%%1")

  -- run the following code once in the first match on the first file
  insert_filter(make, ".*", function()
    -- for _, match in ipairs(make.matches) do
    --   match.params.outdir = outdir
    --   print(match.pattern, match.params.outdir)
    -- end
    -- make the YAML header only for the main HTML file
    make:match(mainfile .. ".html", process)
    make:match(".*", copy_files, {slug=slug})
  end)

  return make
end

return M
