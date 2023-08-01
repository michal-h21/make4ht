local M = {}
local mkutils = require "mkutils"
local domfilter = require "make4ht-domfilter"

local copied_images = {}

local function image_copy(path, parameters, img_dir)
  if mkutils.is_url(path) then return nil, "External image" end
  -- get image basename
  local basename = path:match("([^/]+)$")
  -- if outdir is empty, keep it empty, otherwise add / separator
  local outdir = parameters.outdir == "" and "" or parameters.outdir .. "/"
  if img_dir ~= "" then 
    outdir = outdir .. img_dir .. "/"
  end
  -- handle trailing //
  outdir = outdir:gsub("%/+","/")
  local output_file = outdir .. basename
  if outdir == "" then
    mkutils.cp(path, output_file)
  else
    mkutils.copy(path, output_file)
  end
end

-- filters support only html formats
function M.test(format)
  current_format = format
  if format == "odt" then return false end
  return true
end

function M.modify_build(make)
  local ext_settings = get_filter_settings "copy_images" or {}
  local img_dir = ext_settings.img_dir or ""
  local img_extensions = ext_settings.extensions or {"jpg", "png", "jpeg", "svg"}
  local process = domfilter({
    function(dom, par)
      for _, img in ipairs(dom:query_selector("img")) do
        local src = img:get_attribute("src")
        if src and not mkutils.is_url(src) then
          -- remove path specification
          src = src:match("([^/]+)$")
          if img_dir ~= "" then
            src = img_dir .. "/" ..  src
            src = src:gsub("%/+", "/")
          end
          img:set_attribute("src", src)
        end
      end
      return dom
    end
  }, "copy_images")

  -- add matcher for all image extensions
  for _, ext in ipairs(img_extensions) do
    make:match(ext .. "$", function(path, parameters)
      image_copy(path, parameters, img_dir)
      -- prevent further processing of the image
      return false
    end)
  end

  make:match("html$", process, {img_dir = img_dir})
  return make
end

return M
