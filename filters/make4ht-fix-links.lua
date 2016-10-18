-- replace colons in `id` or `href` attributes for local links with underscores
--

local function fix_href_colons(s)
  return s:gsub('(href=".-")', function(a)
    if a:match("[a-z]%://") then return a end
    return a:gsub(":","_")
  end)
end

local function fix_id_colons(s)
  return s:gsub('(id=".-")', function(a)
    return a:gsub(":", "_")
  end)
end

return function(s)
  return fix_id_colons(fix_href_colons(s))
end
