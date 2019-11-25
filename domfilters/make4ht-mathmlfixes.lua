-- <mglyph> should be inside <mi>, so we don't process it 
-- even though it is  a token element
local token = {"mi", "mn", "mo", "mtext", "mspace", "ms"}
local token_elements = {}
for _, tok in ipairs(token) do token_elements[tok] = true end

local function fix_token_elements(el)
  if token_elements[el._name] then
    local parent = el:get_parent()
    if token_elements[parent._name] then
      -- change top element in nested token elements to mstyle
      parent._name = "mstyle"
    end
  end
end

return function(dom)
  dom:traverse_elements(function(el)
    -- find token elements that are children of other token elements
    fix_token_elements(el)
  end)
  return dom
end

