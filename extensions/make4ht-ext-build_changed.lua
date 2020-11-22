-- this make4ht build file tries to recompile modified blog article sources
--

-- disable any compilation
Make.build_seq = {}
Make:add("tex4ht", "")
Make:add("t4ht", "")

local log = logging.new "compile newest"



-- construct the name of the generated HTML file from the .published file
local function get_generated_html_name(published_file, directory, file_pattern)
  local f = io.open(directory .. "/" .. published_file, "r")
  local content = f:read("*all")
  f:close()
  local timestamp = tonumber(content)
  local basename = mkutils.remove_extension(published_file)
  local tex_file = basename .. ".tex"
  -- expand fillename in the file_pattern
  local expanded = file_pattern % {input = basename}
  -- expand date in the file_pattern 
  expanded = os.date(expanded, timestamp)
  log:status("found source files :", directory, basename, expanded)
  return {directory = directory, tex_file = tex_file, generated = expanded .. ".html"}
end

-- process subdirectories of the basedir and look for the filename.published files
local function find_published(basedir, file_pattern)
  local published = {}
  for f in lfs.dir(basedir) do
    local fullname = basedir .. "/" .. f
    local attributes = lfs.attributes(fullname)
    -- process directories, but ignore . and ..
    if attributes.mode == "directory" and f ~= "." and f~= ".." then
      for name in lfs.dir(fullname) do
        if name:match("published$") then
          published[#published + 1]  =  get_generated_html_name(name, fullname, file_pattern)
        end

      end
    end
  end
  return published
end

-- find tex files that were modified later than the generated HTML files
local function find_changed(published, site_root)
  local keep = {}
  for _, entry in ipairs(published) do
    local source_attributes = lfs.attributes(entry.directory .. "/" .. entry.tex_file)
    local dest_attributes = lfs.attributes(site_root .. "/" .. entry.generated)
    -- 
    print(entry.tex_file, entry.generated,  source_attributes.change < dest_attributes.change)
  end
end


Make:add("rebuild", function(par)
  local config = get_filter_settings "staticsite"
  -- how the generated HTML files are named
  local file_pattern = config.file_pattern or "%Y-%m-%d-${input}"
  local published = find_published(par.tex_dir, file_pattern)
  local changed = find_changed(published, config.site_root)
end)

Make:rebuild{tex_dir = "posts"}
