local M = {}
local filter = require "make4ht-filter"
local mkutils = require "mkutils"

-- get the published file name
local function get_slug(settings)
  local published_name = mkutils.remove_extension(settings.tex_file) .. ".published"

  local slug = os.date("%Y-%m-%d-" .. settings.input)
  -- we must save the published date, so the subsequent compilations at different days
  -- use the same name
  if mkutils.file_exists(published_name) then
    local f = io.open(published_name, "r")
    slug = f:read("*line")
    print("Already pubslished", slug)
    f:close()
  else
    -- escape 
    -- slug must contain the unescaped input name
    local f = io.open(published_name, "w")
    f:write(slug)
    f:close()
    -- make the output file name in the format YYYY-MM-DD-old-filename.html
  end
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

function M.modify_build(make)
  -- it is necessary to insert the filters for YAML header and file copying as last matches
  -- we use an bogus match which will be executed only once as the very first one to insert
  -- the filters
  local insert_executed = false
  local function insert_filter(outdir)
    if not insert_executed  then
      table.insert(make.matches, 1, {
        pattern=".*",
        params = {},
        command = function()
          for _, match in ipairs(make.matches) do
            match.params.outdir = outdir
            print(match.pattern, match.params.outdir)
          end
        end
      })
    end
    insert_executed = true

    -- local first = make.matches[1]
    -- for k,v in pairs(first) do
    --   print("xxx",k,v)
    -- end
    -- os.exit()
  end
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
    cmd.params.latex_par = "-jobname="..slug -- update_jobname(slug, cmd.params.latex_par)
  end

  -- get extension settings
  local site_settings = get_filter_settings "staticsite"
  local outdir = site_settings.output_dir

  insert_filter(outdir)

  local quotepattern = '(['..("%^$().[]*+-?"):gsub("(.)", "%%%1")..'])'
  local mainfile = string.gsub(slug, quotepattern, "%%%1")
  -- is this useful for anything?
  make:match("tmp$", function(a) 
    print "publish jede"
    print("input",settings.input)
    for k,v in pairs(settings.extensions) do
      print("extension", k)
      for x,y in pairs(v) do print(x,y) end
    end
    -- this doesn't work. why?
    return a
  end)

  -- make the YAML header only for the main HTML file
  make:match(mainfile .. ".html", process)
  return make
end

return M
