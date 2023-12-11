local dvireader = require "make4ht-dvireader"
local mkutils = require "mkutils"
local filter = require "make4ht-filter"
local log = logging.new "dvisvgm_hashes"


local dvisvgm_par = {}

local M = {}
-- mapping between tex4ht image names and hashed image names
local output_map = {}
local dvisvgm_options = "-n --exact -c ${scale},${scale}"
local parallel_size = 64
-- local parallel_size = 3

local function make_hashed_name(base, hash)
  return base .. "-" ..hash..".svg"
end

-- detect the number of available processors
local cpu_cnt = 3  -- set a reasonable default for non-Linux systems

if os.name == 'linux' then
  cpu_cnt = 0
  local cpuinfo=assert(io.open('/proc/cpuinfo', 'r'))
  for line in cpuinfo:lines() do
    if line:match('^processor') then
      cpu_cnt = cpu_cnt + 1
    end
  end
  -- set default number of threds if no CPU core have been found
  if cpu_cnt == 0 then cpu_cnt = 1 end
  cpuinfo:close()
elseif os.name == 'cygwin' or os.type == 'windows' then
  -- windows has NUMBER_OF_PROCESSORS environmental value
  local nop = os.getenv('NUMBER_OF_PROCESSORS')
  if tonumber(nop) then
    cpu_cnt = nop
  end
end



-- process output of dvisvgm and find output page numbers and corresponding files
local function get_generated_pages(output, pages)
  local pages = pages or {}
  local pos = 1
  local pos, finish, page = string.find(output, "processing page (%d+)", pos)
  while(pos) do
    pos, finish, file = string.find(output, "output written to ([^\n]+)", finish)
    pages[tonumber(page)] = file
    if not finish then break end
    pos, finish, page = string.find(output, "processing page (%d+)", finish)
  end
  return pages
end

local function make_ranges(pages)
  local newpages = {}
  local start, stop
  for i=1,#pages do
    local current = pages[i]
    local next_el = pages[i+1] or current + 100 -- just select a big number
    local diff = next_el - current
    if diff == 1 then
      if not start then start = current end
    else
      local element
      if start then
        element = start .. "-" .. current
      else
        element = current
      end
      newpages[#newpages+1] = element
      start = nil
    end
  end
  return newpages
end

local function read_log(dvisvgmlog)
  local f = io.open(dvisvgmlog, "rb")
  if not f then return nil, "Cannot read dvisvgm log" end
  local output = f:read("*all")
  f:close()
  return output
end

-- test the existence of GNU Make, which can execute tasks in parallel
local function test_make()
  local make = io.popen("make -v", "r")
  if not make then return false end
  local content = make:read("*all")
  make:close()
  return true
end

local function save_file(filename, text)
  local f = io.open(filename, "w")
  f:write(text) 
  f:close()
end


local function make_makefile_command(idvfile, page_sequences)
  local logs = {}
  local all = {} -- list of targets in the "all:" makefile target
  local targets = {}
  local basename = idvfile:gsub(".idv$", "")
  local makefilename = basename .. "-images" .. ".mk"
  -- build make targets
  for i, ranges in ipairs(page_sequences) do
    local target = basename .. "-" .. i
    local logfile = target .. ".dlog"
    logs[#logs + 1] = logfile
    all[#all+1] = target
    local chunk = target .. ":\n\tdvisvgm -v4 " .. dvisvgm_options .. " -p " .. ranges  .. " " .. idvfile .. " 2> " .. logfile .. "\n"
    targets[#targets + 1] = chunk
  end
  -- construct makefile and save it
  local makefile = "all: " .. table.concat(all, " ") .. "\n\n" .. table.concat(targets, "\n")
  save_file(makefilename, makefile)
  local command = "make -j" .. cpu_cnt .." -f " .. makefilename
  return command, logs
end

local function prepare_command(idvfile, pages)
  local logs = {}
  if #pages > parallel_size and test_make() then 
    local page_sequences = {}
    for i=1, #pages, parallel_size do
      local current_pages = {}
      for x = i, i+parallel_size -1 do
        current_pages[#current_pages + 1] = pages[x]
      end
      table.insert(page_sequences,table.concat(make_ranges(current_pages), ","))
    end
    return make_makefile_command(idvfile, page_sequences)
  end
  -- else
    local pagesequence = table.concat(make_ranges(pages), ",")
    -- the stderr from dvisvgm must be redirected and postprocessed
    local dvisvgmlog = idvfile:gsub("idv$", "dlog")
    -- local dvisvgm = io.popen("dvisvgm -v4 -n --exact -c 1.15,1.15 -p " .. pagesequence .. " " .. idvfile, "r")
    local command = "dvisvgm -v4 " .. dvisvgm_options .. " -p " .. pagesequence .. " " .. idvfile .. " 2> " .. dvisvgmlog
    return command, {dvisvgmlog}
  -- end
end

local function execute_dvisvgm(idvfile, pages)
  if #pages < 1 then return nil, "No pages to convert" end
  local command, logs = prepare_command(idvfile, pages)
  log:info(command)
  os.execute(command)
  local generated_pages = {}
  for _, dvisvgmlog in ipairs(logs) do
    local output = read_log(dvisvgmlog)
    generated_pages = get_generated_pages(output, generated_pages)
  end
  return generated_pages
end

local function get_dvi_pages(arg)
  -- list of pages to convert in this run
  local to_convert = {}
  local idv_file = arg.input .. ".idv"
  -- set extension options
  local extoptions = mkutils.get_filter_settings "dvisvgm_hashes" or {}
  dvisvgm_options = arg.options or extoptions.options or dvisvgm_options
  parallel_size = arg.parallel_size or extoptions.parallel_size or parallel_size
  cpu_cnt = arg.cpu_cnt or extoptions.cpu_cnt or cpu_cnt
  dvisvgm_par.scale = arg.scale or extoptions.scale or 1.15
  dvisvgm_options = dvisvgm_options % dvisvgm_par
  local f = io.open(idv_file, "rb")
  if not f then return nil, "Cannot open idv file: " .. idv_file end
  local content = f:read("*all")
  f:close()
  local dvi_pages = dvireader.get_pages(content)
  -- we must find page numbers and output name sfor the generated images
  local lg = mkutils.parse_lg(arg.input ..".lg", arg.builddir)
  for _, name in ipairs(lg.images) do
    local page = tonumber(name.page)
    local hash = dvi_pages[page]
    local tex4ht_name = name.output
    local output_name = make_hashed_name(arg.input, hash)
    output_map[tex4ht_name] = output_name
    if not mkutils.file_exists(output_name) then
      log:debug("output file: ".. output_name)
      to_convert[#to_convert+1] = page
    end
  end
  local generated_files, msg = execute_dvisvgm(idv_file, to_convert)
  if not generated_files then
    return nil, msg
  end

  -- rename the generated files to the hashed filenames
  for page, file in pairs(generated_files) do
    os.rename(file, make_hashed_name(arg.input, dvi_pages[page]))
  end

end

function M.test(format)
  -- ODT format doesn't support SVG
  if format == "odt" then return false end
  return true
end

function M.modify_build(make)
  -- this must be used in the .mk4 file as
  -- Make:dvisvgm_hashes {}
  make:add("dvisvgm_hashes", function(arg)
    get_dvi_pages(arg)
  end, 
  {
  })

  -- insert dvisvgm_hashes command at the end of the build sequence -- it needs to be called after t4ht
  make:dvisvgm_hashes {}

  -- replace original image names with hashed names
  local executed = false
  make:match(".*", function(arg)
    if not executed then
      executed = true
      local lgfiles = make.lgfile.files
      for i, filename in ipairs(lgfiles) do
        local replace = output_map[filename]
        if replace then
          lgfiles[i] = replace
        end
      end
      -- tex4ebook process also the images table, so we need to replace generated filenames here as well
      local lgimages = make.lgfile.images
      for _, image in ipairs(lgimages) do
        local  replace = output_map[image.output]
        if replace then
          image.output = replace
        end
      end
    end
  end)

  -- fix src attributes
  local process = filter({
    function(str, filename)
      return str:gsub('src=["\'](.-)(["\'])', function(filename, endquote)
        local newname = output_map[filename] or filename
        log:debug("newname", newname)
        return 'src=' .. endquote .. newname  .. endquote
      end)
    end
  }, "dvisvgmhashes")

  make:match("htm.?$", process)

  -- disable the image processing
  for _,v in ipairs(make.build_seq) do
    if v.name == "t4ht" then
      local t4ht_par = v.params.t4ht_par or make.params.t4ht_par or ""
      v.params.t4ht_par = t4ht_par .. " -p"
    end
  end
  make:image(".", function() return "" end)
  return make
end

return M
