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
        parent._attr = parent._attr or {}
        parent:set_attribute("mathvariant", mathvariant)
      end
      -- copy the contents of <mstyle> to the parent element
      parent._children = el._children
    end
  end
end

-- if element contains 
-- wrap everything in <mrow>
local function top_mrow(math)
  local children = math:get_children()
  local put_mrow = false
  -- don't process elements with one or zero children
  -- don't process elements that already are mrow
  if #children < 2 or  math:get_element_name() == "mrow" then return nil end
  for _,v in ipairs(children) do
    if v:is_element() and is_token_element(v) then
      put_mrow = true
      break
    end
  end
  if put_mrow then
    local mrow = math:create_element("mrow")
    for _, el in ipairs(children) do
      mrow:add_child_node(el)
    end
    math._children = {mrow}
  end

end

local function get_fence(el, attr, form)
  -- convert fence attribute to <mo> element
  -- attr: open | close
  -- form: prefix | postfix
  local char = el:get_attribute(attr)
  local mo 
  if char then
    mo = el:create_element("mo", {fence="true", form = form})
    mo:add_child_node(mo:create_text_node(char))
  end
  return mo
end


local function fix_mfenced(el)
  -- TeX4ht uses in some cases <mfenced> element which is deprecated in MathML.
  -- Firefox doesn't support it already.
  if el:get_element_name() == "mfenced" then
    -- we must replace it by <mrow><mo>start</mo><mfenced children...><mo>end</mo></mrow>
    local open = get_fence(el, "open", "prefix")
    local close = get_fence(el, "close", "postfix")
    -- there can be also separator attribute, but it is not used in TeX4ht
    -- change <mfenced> to <mrow> and remove all attributes
    el._name = "mrow"
    el._attr = {}
    -- open must be first child, close needs to be last
    if open then el:add_child_node(open, 1) end
    if close then el:add_child_node(close) end
  end
end

local function is_fence(el)
  return el:get_element_name() == "mo" and el:get_attribute("fence") == "true"
end

local function fix_mo_to_mfenced(el)
  -- LibreOffice NEEDS <mfenced> element. so we need to convert <mrow><mo fence="true">
  -- to <mfenced>. ouch.
  if is_fence(el) then
    local parent = el:get_parent()
    local open = el:get_text():gsub("%s*", "") -- convert mo content to text, so it can be used in 
    -- close needs to be the last element in the sibling list of the current element
    local siblings = el:get_siblings()
    el:remove_node() -- we don't need this element anymore
    local close
    for i = #siblings, 1, -1 do
      last = siblings[i]
      if last:is_element() then
        if is_fence(last) then -- set close attribute only if the last element is fence
          close = last:get_text():gsub("%s*", "")
          last:remove_node() -- remove <mo>
        end
        break -- break looping over elements once we find last element
      end 
    end
    -- convert parent <mrow> to <mfenced>
    parent._name = "mfenced"
    parent._attr = {open = open, close = close}
  end
end

return function(dom)
  dom:traverse_elements(function(el)
    if settings.output_format ~= "odt" then
      -- LibreOffice needs <mfenced>, but Firefox doesn't
      fix_mfenced(el)
    else
      fix_mo_to_mfenced(el)
    end
    fix_token_elements(el)
    fix_nested_mstyle(el)
    top_mrow(el)
  end)
  return dom
end

