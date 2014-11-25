-- cleanspan function submitted by Nat Kuhn 
-- http://www.natkuhn.com/

local function filter(s)
    local pattern = "(<span%s+([^>]+)>[^<]*)</span>(%s*)<span%s+%2>"
    repeat
      s, n = s:gsub(pattern, "%1%3")
    until n == 0
    return s
end

return filter
