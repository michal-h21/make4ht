local M = {}

-- this extension covnerts links, tables of contents and other dynamic content in the ODT format to plain text

local filter = require "make4ht-domfilter"

-- this extension only works for the ODT format
M.test = function(format)
  return format=="odt"
end

local function nodynamiccontent(dom)
  for _,link in ipairs(dom:query_selector("text|a")) do
    -- change links to spans
    link._name = "text:span"
    -- remove attributes
    link._attr = {}

  end
  for _, bibliography in ipairs(dom:query_selector("text|bibliography")) do
    -- remove links from bibliography
    -- use div instead of bibliography
    bibliography._name = "text:div"
    -- remove bibliography-source elements
    for _, source in ipairs(bibliography:query_selector("text:bibliography-source")) do
      source:remove_node()
    end
    for _, index in ipairs(bibliography:query_selector("text|index-body")) do
      -- use div instead of bibliography-entry
      index._name = "text:div"
    end

  end
  for _, toc in ipairs(dom:query_selector("text|table-of-content")) do
    -- remove links from toc
    -- use div instead of table-of-contents
    toc._name = "text:div"
    for _, entry in ipairs(toc:query_selector("text|index-body, text|index-title")) do
      -- use div instead of table-of-contents-entry
      entry._name = "text:div"
    end
  end
  return dom
end

M.modify_build = function(make)
  local process = filter({nodynamiccontent}, "nodynamiccontent")
  Make:match("4oo$",process)
  return make
end

return M
