local log = logging.new("mathmlfixes")
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

local function fix_mathvariant(el)
  -- set mathvariant of <mi> that is child of <mstyle> to have the same value
  local function find_mstyle(x)
    -- find if element has <mstyle> parent, and its value of mathvariant
    if not x:is_element() then
      return nil
    elseif x:get_element_name() == "mstyle" then 
      return x:get_attribute("mathvariant")
    else
      return find_mstyle(x:get_parent())
    end
  end
  if el:get_element_name() == "mi" then
    -- process only <mi> that have mathvariant set
    local oldmathvariant = el:get_attribute("mathvariant")
    if oldmathvariant then
      local mathvariant = find_mstyle(el:get_parent())
      if mathvariant then
        el:set_attribute("mathvariant", mathvariant)
      end
    end
  end
end

-- put <mrow> as child of <math> if it already isn't here
local allowed_top_mrow = {
  math=true
}
local function top_mrow(math)
  local children = math:get_children()
  local put_mrow = false
  -- don't process elements with one or zero children
  -- don't process elements that already are mrow
  local parent = math:get_parent()
  local parent_name
  if parent then parent_name = parent:get_element_name() end
  local current_name = math:get_element_name()
  if #children < 2 or not allowed_top_mrow[current_name] or current_name == "mrow" or parent_name == "mrow" then return nil end
  local mrow_count = 0
  for _,v in ipairs(children) do
    if v:is_element() and is_token_element(v) then
      put_mrow = true
      -- break
    elseif v:is_element() and v:get_element_name() == "mrow" then
      mrow_count = mrow_count + 1
    end
  end
  if not put_mrow and math:get_element_name() == "math" and mrow_count == 0 then
    -- put at least one <mrow> to each <math>
    put_mrow = true
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

local function fix_numbers(el)
  -- convert <mn>1</mn><mo>.</mo><mn>3</mn> to <mn>1.3</mn>
  if el:get_element_name() == "mn" then
    local n = el:get_sibling_node(1)
    -- test if next  element is <mo class="MathClass-punc">.</mo>
    if n and n:is_element() 
         and n:get_element_name() == "mo" 
         and n:get_attribute("class") == "MathClass-punc" 
         and n:get_text() == "." 
    then
      -- get next element and test if it is <mn>
      local x = el:get_sibling_node(2)
      if x and x:is_element() 
           and x:get_element_name() == "mn" 
      then
        -- join numbers and set it as text content of the current element
        local newnumber = el:get_text() .. "." .. x:get_text()
        log:debug("Joining numbers: " .. newnumber)
        el._children = {}
        local newchild = el:create_text_node(newnumber)
        el:add_child_node(newchild)
        -- remove elements that hold dot and decimal part
        n:remove_node()
        x:remove_node()
      end
    end
  end
end


local function just_operators(list)
  -- count <mo> and return true if list contains just them
  local mo = 0
  for _, x in ipairs(list) do
    if x:get_element_name() == "mo" then mo = mo + 1 end
  end
  return mo
end


local function fix_operators(x)
  -- change <mo> elements that are only children of any element to <mi>
  -- this fixes issues in LibreOffice with a^{*}
  -- I hope it doesn't introduce different issues
  -- process only <mo>
  if x:get_element_name() ~= "mo" then return nil end
	local siblings = x:get_siblings()
	-- test if current element list contains only <mo>
	if just_operators(siblings) == #siblings then
		if #siblings == 1 then
			-- one <mo> translates to <mtext>
			x._name = "mtext"
      log:debug("changing one <mo> to <mtext>: " .. x:get_text())
      -- I think we should use <mi>, but LO incorrectly renders it in <msubsup>,
      -- even if we use the mathvariant="normal" attribute. <mtext> works, so
      -- we use that instead.
			-- x:set_attribute("mathvariant", "normal")
		else
			-- multiple <mo> translate to <mtext>
			local text = {}
			for _, el in ipairs(siblings) do
				text[#text+1] = el:get_text()
			end
			-- replace first <mo> text with concetanated text content
			-- of all <mo> elements
			x._children = {}
      local newtext = table.concat(text)
			local text_el = x:create_text_node(newtext)
      log:debug("changing <mo> to <mtext>: " .. newtext)
      x:add_child_node(text_el)
      -- change <mo> to <mtext>
      x._name = "mtext"
      -- remove subsequent <mo>
      for i = 2, #siblings do
        siblings[i]:remove_node()
      end
    end
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
    fix_numbers(el)
    fix_operators(el)
    fix_mathvariant(el)
    top_mrow(el)
  end)
  return dom
end

