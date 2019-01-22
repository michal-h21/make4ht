local mkutils = require "mkutils"
local zip = require "zip"
local domobject = require "luaxml-domobject"


local function get_template_filename(settings)
  -- either get the template odt filename from tex4ht.sty options (make4ht filename.tex "odttemplate=test.odt")
  local tex4ht_settings = settings.tex4ht_sty_par
  local templatefile = tex4ht_settings:match("odttemplate=([^%,]+)")
  if templatefile then return templatefile end
  -- read the template odt filename from settings
  local filtersettings = get_filter_settings "odttemplate"
  return settings.template or filtersettings.template
end

local function join_styles(old, new)
  local old_dom = domobject.parse(old)
  local new_dom = domobject.parse(new)

  local template_styles = {}
  local template_obj  -- <office:styles> element, we will add new styles from the generated ODT here

  -- detect style names in the template file and save them in a table for easy accesss
  for _, style in ipairs(new_dom:query_selector("office|styles *")) do
    template_obj = template_obj or style:get_parent()
    local name = style:get_attribute("style:name") -- get the <office:styles> element
    if name then
      template_styles[name] = true
    end
  end

  -- process the generated styles and add ones not used in the template
  for _, style in ipairs(old_dom:query_selector("office|styles *")) do
    local name = style:get_attribute("style:name")
    if name and not template_styles[name] then
      template_obj:add_child_node(style)
    end
  end

  -- return template with additional styles from the generated file
  return new_dom:serialize()
end

return function(content, settings)
  -- use settings added from the Make:match, or default settings saved in Make object
  local templatefile = get_template_filename(settings)
  -- don't do anything if the template file doesn't exist
  if not templatefile or not mkutils.file_exists(templatefile) then return content end
  local odtfile = zip.open(templatefile)
  if odtfile then
    local stylesfile = odtfile:open("styles.xml")
    -- just break if the styles cannot be found
    if not stylesfile then return content end
    local styles = stylesfile:read("*all")
    local newstyle = join_styles(content, styles)
    return newstyle
  end
  -- just return content in the case of problems
  return content
end
