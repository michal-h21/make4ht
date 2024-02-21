local log = logging.new("mathmlfixes")
-- <mglyph> should be inside <mi>, so we don't process it 
-- even though it is  a token element
local token = {"mi", "mn", "mo", "mtext", "mspace", "ms"}
local token_elements = {}
for _, tok in ipairs(token) do token_elements[tok] = true end

-- helper functions to support MathML elements with prefixes (<mml:mi> etc).
--
local function get_element_name(el)
  -- return element name and xmlns prefix
  local name = el:get_element_name()
  if name:match(":") then
    local prefix, real_name =  name:match("([^%:]+):?(.+)")
    return real_name, prefix
  else
    return name
  end
end

local function get_attribute(el, attr_name)
  -- attributes can have the prefix, but sometimes they don't have it
  -- so we need to catch both cases
  local _, prefix = get_element_name(el)
  prefix = prefix or ""
  return el:get_attribute(attr_name) or el:get_attribute(prefix .. ":" .. attr_name)
end

local function get_new_element_name(name, prefix)
  return prefix and prefix .. ":" .. name or name
end

local function update_element_name(el, name, prefix)
  local newname = get_new_element_name(name, prefix)
  el._name = newname
end

local function create_element(el, name, prefix, attributes)
  local attributes = attributes or {}
  local newname = get_new_element_name(name, prefix)
  return el:create_element(newname, attributes)
end

local function element_pos(el)
  local pos, count = 0, 0
  for _, node in ipairs(el:get_siblings()) do
    if node:is_element() then
      count = count + 1
      if node == el then
        pos = count
      end
    end
  end
  return pos, count
end

-- test if element is the first element in the current element list
local function is_first_element(el)
  local pos, count = element_pos(el)
  return pos == 1 
end

-- test if element is the last element in the current element list
local function is_last_element(el)
  local pos, count = element_pos(el)
  return pos == count
end



local function is_token_element(el)
  local name, prefix = get_element_name(el)
  return token_elements[name], prefix
end

local function fix_token_elements(el)
  -- find token elements that are children of other token elements
  if is_token_element(el) then
    local parent = el:get_parent()
    local is_parent_token, prefix = is_token_element(parent)
    if is_parent_token then
      -- change top element in nested token elements to mstyle
      update_element_name(parent, "mstyle", prefix)
    end
  end
end

local function fix_nested_mstyle(el)
  -- the <mstyle> element can be child of token elements
  -- we must exterminate it
  local el_name = get_element_name(el)
  if el_name == "mstyle" then
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
    elseif get_element_name(x) == "mstyle" then 
      return x:get_attribute("mathvariant")
    else
      return find_mstyle(x:get_parent())
    end
  end
  if get_element_name(el) == "mi" then
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

local function contains_only_text(el)
  -- detect if element contains only text
  local elements = 0
  local text     = 0
  local children = el:get_children() or {}
  for _ , child in ipairs(children) do
    if child:is_text() then text = text + 1
    elseif child:is_element() then elements = elements + 1
    end
  end
  return text > 0 and elements == 0
end

-- check if <mstyle> element contains direct text. in that case, add
-- <mtext>
local function fix_missing_mtext(el)
  if el:get_element_name() == "mstyle" and contains_only_text(el) then
    -- add child <mtext>
    log:debug("mstyle contains only text: " .. el:get_text())
    -- copy the current mode, change it's element name to mtext and add it as a child of <mstyle>
    local copy = el:copy_node()
    copy._name = "mtext"
    copy._parent = el
    el._children = {copy}
  end
end

local function is_radical(el)
  local radicals = {msup=true, msub=true, msubsup=true}
  return radicals[el:get_element_name()]
end

local function get_mrow_child(el)
  local get_first = function(x) 
    local children = x:get_children() 
    return children[1]
  end
  local first = get_first(el)
  -- either return first child, and if the child is <mrow>, return it's first child
  if first and first:is_element() then
    if first:get_element_name() == "mrow" then
      return get_first(first), first
    else
      return first
    end
  end
end

local function fix_radicals(el)
  if is_radical(el) then
    local first_child, mrow = get_mrow_child(el)
    -- if the first child is only one character long, it is possible that there is a problem
    if first_child and string.len(first_child:get_text()) == 1 then
      local name = first_child:get_element_name() 
      local siblings = el:get_siblings()
      local pos = el:find_element_pos()
      -- it doesn't make sense to do any further processing if the element is at the beginning
      if pos == 1 then return end
      if name == "mo" then
        for i = pos, 1,-1 do
        end

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
  if parent then parent_name = get_element_name(parent) end
  local current_name, prefix = get_element_name(math)
  if #children < 2 or not allowed_top_mrow[current_name] or current_name == "mrow" or parent_name == "mrow" then return nil end
  local mrow_count = 0
  for _,v in ipairs(children) do
    if v:is_element() and is_token_element(v) then
      put_mrow = true
      -- break
    elseif v:is_element() and get_element_name(v) == "mrow" then
      mrow_count = mrow_count + 1
    end
  end
  if not put_mrow and get_element_name(math) == "math" and mrow_count == 0 then
    -- put at least one <mrow> to each <math>
    put_mrow = true
  end
  if put_mrow then
    local newname = get_new_element_name("mrow", prefix)
    local mrow = math:create_element(newname)
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
    local name, prefix = get_element_name(el)
    local newname = get_new_element_name("mo", prefix)
    mo = el:create_element(newname, {fence="true", form = form})
    mo:add_child_node(mo:create_text_node(char))
  end
  return mo
end


local function fix_mfenced(el)
  -- TeX4ht uses in some cases <mfenced> element which is deprecated in MathML.
  -- Firefox doesn't support it already.
  local name, prefix = get_element_name(el)
  if name == "mfenced" then
    -- we must replace it by <mrow><mo>start</mo><mfenced children...><mo>end</mo></mrow>
    local open = get_fence(el, "open", "prefix")
    local close = get_fence(el, "close", "postfix")
    -- there can be also separator attribute, but it is not used in TeX4ht
    -- change <mfenced> to <mrow> and remove all attributes
    local newname = get_new_element_name("mrow", prefix)
    el._name = newname
    el._attr = {}
    -- open must be first child, close needs to be last
    if open then el:add_child_node(open, 1) end
    if close then el:add_child_node(close) end
  end
end

local function is_fence(el)
  return get_element_name(el) == "mo" and el:get_attribute("fence") == "true"
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
    local _, prefix = get_element_name(parent)
    local newname = get_new_element_name("mfenced", prefix)
    parent._name = newname
    parent._attr = {open = open, close = close}
  end
end

local function fix_numbers(el)
  -- convert <mn>1</mn><mo>.</mo><mn>3</mn> to <mn>1.3</mn>
  if get_element_name(el) == "mn" then
    -- sometimes minus sign can be outside <mn>
    local x = el:get_sibling_node(-1)
    if x and x:is_text()
         and x:get_text() == "−" 
    then
      el:add_child_node(x:copy_node(), 1)
      x:remove_node()
    end
    local n = el:get_sibling_node(1)
    -- test if next  element is <mo class="MathClass-punc">.</mo>
    if n and n:is_element() 
         and get_element_name(n) == "mo" 
         and get_attribute(n, "class") == "MathClass-punc" 
         and n:get_text() == "." 
    then
      -- get next element and test if it is <mn>
      local x = el:get_sibling_node(2)
      if x and x:is_element() 
           and get_element_name(x) == "mn" 
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
    if get_element_name(x) == "mo" then mo = mo + 1 end
  end
  return mo
end


local function fix_operators(x)
  -- change <mo> elements that are only children of any element to <mi>
  -- this fixes issues in LibreOffice with a^{*}
  -- I hope it doesn't introduce different issues
  -- process only <mo>
  local el_name, prefix = get_element_name(x)
  if el_name ~= "mo" then return nil end
	local siblings = x:get_siblings()
	-- test if current element list contains only <mo>
	if just_operators(siblings) == #siblings then
		if #siblings == 1 then
      if not x:get_attribute("stretchy") then
        -- one <mo> translates to <mtext>
        local newname = get_new_element_name("mtext", prefix)
        x._name = newname
        log:debug("changing one <mo> to <mtext>: " .. x:get_text())
        -- I think we should use <mi>, but LO incorrectly renders it in <msubsup>,
        -- even if we use the mathvariant="normal" attribute. <mtext> works, so
        -- we use that instead.
        -- x:set_attribute("mathvariant", "normal")
      end
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
      local newname = get_new_element_name("mtext", prefix)
      x._name = newname
      -- remove subsequent <mo>
      for i = 2, #siblings do
        siblings[i]:remove_node()
      end
    end
  end
end

local function get_third_parent(el)
  local first = el:get_parent()
  if not first then return nil end
  local second = first:get_parent()
  if not second then return nil end
  return second:get_parent()
end

local function add_space(el, pos)
  local parent = el:get_parent()
  local name, prefix = get_element_name(el)
  local space = create_element(parent, "mspace", prefix)
  space:set_attribute("width", "0.3em")
  parent:add_child_node(space, pos)
end

local function fix_dcases(el)
	-- we need to fix spacing in dcases* environments
	-- when you use something like:
	-- \begin{dcases*}
	-- 1 & if $a=b$ then
	-- \end{dcases*}
	-- the spaces around $a=b$ will be missing
	-- we detect if the <mtext> elements contains spaces that are collapsed by the browser, and add explicit <mspace>
	-- elements when necessary
	if el:get_element_name() == "mtext" then
		local parent = get_third_parent(el)
		if parent and parent:get_element_name() == "mtable" and parent:get_attribute("class") == "dcases-star" then
			local text = el:get_text()
			local pos = el:find_element_pos()
			if pos == 1 and text:match("%s$") then 
				add_space(el, 2)
			elseif text:match("^%s") and not el._used then
				add_space(el, pos)
				-- this is necessary to avoid infinite loop, we mark this element as processed
				el._used = true
			end
		end
	end
end

local function is_empty_row(el)
  -- empty row should contain only one <mtd>
  local count = 0
  if el:get_text():match("^%s*$") then
    for _, child in ipairs(el:get_children()) do
      if child:is_element() then count = count + 1 end
    end
  else
    -- row is not empty if it contains any text
    return false
  end
  -- if there is one or zero childrens, then it is empty row
  return count < 2
end


local function delete_last_empty_mtr(el)
  -- arrays sometimes contain last empty row, which causes rendering issues,
  -- so we should remove them
  local el_name, prefix = get_element_name(el)
  if el_name == "mtr" 
    and get_attribute(el, "class") == "array-row" 
    and is_last_element(el)
    and is_empty_row(el)
  then
    el:remove_node()
  end

end

local function fix_rel_mo(el)
  -- this is necessary for LibreOffice. It has a problem with relative <mo> that are
  -- first childs in an element list. This often happens in equations, where first
  -- element in a table column is an operator, like non-equal-, less-than etc.
  local el_name, prefix = get_element_name(el)
  if el_name == "mo" 
     and not get_attribute(el, "fence") -- ignore fences
     and not get_attribute(el, "form")  -- these should be also ignored
     and not get_attribute(el, "accent") -- and accents too
  then
    local parent = el:get_parent()
    if is_first_element(el) then
      local mrow = create_element(parent, "mrow", prefix)
      parent:add_child_node(mrow, 1)
    elseif is_last_element(el) then
      local mrow = create_element(parent, "mrow", prefix)
      parent:add_child_node(mrow)
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
      fix_rel_mo(el)
    end
    fix_radicals(el)
    fix_token_elements(el)
    fix_nested_mstyle(el)
    fix_missing_mtext(el)
    fix_numbers(el)
    fix_operators(el)
    fix_mathvariant(el)
    fix_dcases(el)
    top_mrow(el)
    delete_last_empty_mtr(el)
  end)
  return dom
end

