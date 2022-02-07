return function(dom, params)
  -- fix ODT style for fonts 
  -- sometimes, fonts have missing size, we need to patch styles
  local properties = get_filter_settings "odtfonts" or {}
  local fix_lgfile_fonts = params.patched_lg_fonts or properties.patched_lg_fonts or {}
  for _, style in ipairs(dom:query_selector "style|style") do
    local typ  = style:get_attribute("style:family")
    if typ == "text" then
      -- detect if the style is for font
      local style_name = style:get_attribute("style:name")
      local name, size, size2, size3 = style_name:match("(.-)%-(%d*)x%-(%d*)x%-(%d+)")
      if name then
        -- find if the style corresponds to a problematic font (it is set in formats/make4ht-odt.lua)
        local used_name = name .. "-" .. size
        if fix_lgfile_fonts[used_name] then
          -- copy current style and fix the name
          local new = style:copy_node()
          new:set_attribute("style:name", string.format("%s-x-%sx-%s", name, size2, size3))
          local parent = style:get_parent()
          parent:add_child_node(new)
        end
      end
    end
  end
  return dom
end
