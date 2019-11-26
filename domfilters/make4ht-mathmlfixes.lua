-- <mglyph> should be inside <mi>, so we don't process it 
-- even though it is  a token element
local token = {"mi", "mn", "mo", "mtext", "mspace", "ms"}
local token_elements = {}
for _, tok in ipairs(token) do token_elements[tok] = true end

local function is_token_element(el)
  return token_elements[el:get_element_name()]
end

local function fix_token_elements(el)
  -- find token elements that are children of other token elements
  if is_token_element(el) then
    local parent = el:get_parent()
    if is_token_element(parent) then
      -- change top element in nested token elements to mstyle
      parent._name = "mstyle"
    end
  end
end

local function fix_nested_mstyle(el)
  -- the <mstyle> element can be child of token elements
  -- we must exterminate it
  if el:get_element_name() == "mstyle" then
    local parent = el:get_parent()
    if is_token_element(parent) then
      -- if parent doesn't have the mathvariant attribute copy it from <mstyle>
      if not parent:get_attribute("mathvariant") then
        local mathvariant = el:get_attribute("mathvariant") 
        parent:set_attribute("mathvariant", mathvariant)
      end
      -- copy the contents of <mstyle> to the parent element
      parent._children = el._children
    end
  end
end

return function(dom)
  dom:traverse_elements(function(el)
    fix_token_elements(el)
    fix_nested_mstyle(el)
  end)
  return dom
end

