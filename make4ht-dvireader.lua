-- This is not actually full DVI reader. It just calculates hash for each page,
-- so it can be detected if it changed between compilations and needs to be
-- converted to image using Dvisvgm or Dvipng
--
-- information about DVI format is from here: https://web.archive.org/web/20070403030353/http://www.math.umd.edu/~asnowden/comp-cont/dvi.html
--
local M

-- the file after post_post is filled with bytes 223
local endfill = 223

-- numbers of bytes for each data type in DVI file
local int = 4
local byte = 1
local sixteen = 2

local function read_char(str, pos)
  if pos and pos > string.len(str) then return nil end
  return string.sub(str, pos, pos + 1)
end

local function read_byte(str, pos)
  return string.byte(read_char(str, pos))
end

-- DVI file format uses signed big endian integers. This code doesn't take into account 
-- the sign, so it will return incorrect result for negative numbers. It doesn't matter 
-- for the original purpose of this library, but it should be fixed for general use.
local function read_integer(str, pos)
  local first = read_byte(str, pos)
  local num = first * (256 ^ 3)
  num = read_byte(str, pos + 1) * (256 ^ 2) + num
  num = read_byte(str, pos + 2) * 256  + num
  num = read_byte(str, pos + 3) + num
  return num
end

local function read_sixteen(str, pos)
  local num = read_byte(str, pos) * 256 
  num = read_byte(str, pos + 1) + num
  return num
end

-- select reader function with number of bytes of an argument
local readers = {
  [byte] = read_byte,
  [int] = read_integer,
  [sixteen] = read_sixteen
}


local opcodes = {
  post_post = {
    opcode = 249, args = {
      {name="q", type = int}, -- postamble address
      {name="i", type = byte}
    }
  },
  post = {
    opcode = 248,
    args = {
      {name="p", type = int}, -- address of the last page
      {name="num", type = int},
      {name="den", type = int},
      {name="mag", type = int},
      {name="l", type = int},
      {name="u", type = int},
      {name="s", type = sixteen},
      {name="t", type = sixteen},
    }
  },
  bop = {
    opcode = 139,
    args = {
      {name="c0", type=int},
      {name="c1", type=int},
      {name="c2", type=int},
      {name="c3", type=int},
      {name="c4", type=int},
      {name="c5", type=int},
      {name="c6", type=int},
      {name="c7", type=int},
      {name="c8", type=int},
      {name="c9", type=int},
      {name="p", type=int}, -- previous page
    }
  }
}

local function read_arguments(str, pos, args)
  local t = {}
  for _, v in ipairs(args) do
    local fn =  readers[v.type]
    t[v.name] = fn(str, pos)
    -- seek the position. v.type contains size of the current data type in bytes
    pos = pos + v.type
  end
  return t
end

local function read_opcode(opcode, str, pos)
  local format = opcodes[opcode]
  if not format then return nil, "Cannot find opcode format: " .. opcode end
  -- check that opcode byte in the current position is the same as required opcode
  local op = read_byte(str, pos)
  if op ~= format.opcode then return nil, "Wrong opcode " .. op .. " at position " .. pos end
  return read_arguments(str, pos+1, format.args)
end

-- find the postamble address
local function get_postamble_addr(dvicontent)
  local pos = string.len(dvicontent)
  local last = read_char(dvicontent, pos)
  -- skip endfill bytes at the end of file
  while string.byte(last) == endfill do
    pos = pos - 1
    last = read_char(dvicontent, pos)
  end
  -- first read post_post to get address of the postamble
  local post_postamble, msg = read_opcode("post_post", dvicontent, pos-5)
  if not post_postamble then return nil, msg end
  -- return the postamble address
  return post_postamble.q + 1
  -- return read_opcode("post", dvicontent, post_postamble.q + 1)

end

local function read_page(str, start, stop)
  local function get_end_of_page(str, pos)
    if read_byte(str, pos) == 140 then -- end of page
      return pos
    end
    return get_end_of_page(str, pos - 1)
  end
  -- we reached the end of file
  if start == 2^32-1 then return nil end
  local current_page = read_opcode("bop", str,  start + 1)
  if not current_page then return nil end
  local endofpage = get_end_of_page(str, stop)
  -- get the page contents, but skip all parameters, because they can change
  -- (especially pointer to the previous page)
  local page = str:sub(start + 46, endofpage) 
  local page_obj = {
    number = current_page.c0, -- the page number
    hash = md5.sumhexa(page) -- hash the page contents
  }
  return page_obj, current_page.p, start
end

local function get_pages(dvicontent)
  local pages = {}
  local postamble_pos = get_postamble_addr(dvicontent)
  local postamble = read_opcode("post", dvicontent, postamble_pos)
  local next_page_pos = postamble.p 
  local page, previous_page = nil, postamble_pos
  local page_sequence = {}
  while next_page_pos do
    page, next_page_pos, previous_page = read_page(dvicontent, next_page_pos, previous_page)
    page_sequence[#page_sequence+1] = page
  end

  -- reorder pages
  for _, v in ipairs(page_sequence) do
    pages[v.number] = v.hash
  end
  return pages

end

-- if arg[1] then
--   local f = io.open(arg[1], "r")
--   local dvicontent = f:read("*all")
--   f:close()
--   local pages = get_pages(dvicontent)
--   for k,v in pairs(pages) do 
--     print(k,v)
--   end
-- end

return {
  get_pages = get_pages
}
