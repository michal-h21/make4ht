-- source: https://github.com/leafo/web_sanitize/blob/master/web_sanitize/query/parse_query.lua
local R, S, V, P
do
  local _obj_0 = require("lpeg")
  R, S, V, P = _obj_0.R, _obj_0.S, _obj_0.V, _obj_0.P
end
local C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp
do
  local _obj_0 = require("lpeg")
  C, Cs, Ct, Cmt, Cg, Cb, Cc, Cp = _obj_0.C, _obj_0.Cs, _obj_0.Ct, _obj_0.Cmt, _obj_0.Cg, _obj_0.Cb, _obj_0.Cc, _obj_0.Cp
end
local alphanum = R("az", "AZ", "09")
local num = R("09")
local white = S(" \t\n") ^ 0
local word = (alphanum + S("_-")) ^ 1
local mark
mark = function(name)
  return function(...)
    return {
      name,
      ...
    }
  end
end
local parse_query
parse_query = function(query)
  local tag = word / mark("tag")
  local cls = P(".") * (word / mark("class"))
  local id = P("#") * (word / mark("id"))
  local any = P("*") / mark("any")
  local nth = P(":nth-child(") * C(num ^ 1) * ")" / mark("nth-child")
  local first = P(":first-child") / mark("first-child")
  local attr = P("[") * C(word) * P("]") / mark("attr")
  local selector = Ct((any + nth + first + tag + cls + id + attr) ^ 1)
  local pq = Ct(selector * (white * selector) ^ 0)
  local pqs = Ct(pq * (white * P(",") * white * pq) ^ 0)
  pqs = pqs * (white * -1)
  return pqs:match(query)
end
return {
  parse_query = parse_query
}
