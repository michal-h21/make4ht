-- TeX4ht puts contents of all \item commands into paragraphs. We are not
-- able to detect if it contain only one paragraph, or more. If just one,
-- we can remove the paragraph and put the contents directly to <li> element.
return function(dom)
  for _, li in ipairs(dom:query_selector("li")) do
    local par = li:query_selector("p") 
    if #par == 1 then
      -- place paragraph children as direct children of <li>, this
      -- efectivelly removes <p>
      li._children = par[1]._children
    end
  end
  return dom
end
