require "busted.runner" ()
kpse.set_program_name "luatex"

local dom = require "make4ht-dom"

describe("Basic DOM functions", function() 
  local document = [[
  <html>
  <head><title>pokus</title></head>
  <body>
  <h1>pokus</h1>
  <p>nazdar</p>
  </body>
  </html>
  ]]

  local obj = dom.parse(document)
  it("It should parse XML", function()
    assert.truthy(type(obj), "table")
    assert.truthy(obj:root_node())
  end)

  it("Path retrieving should work", function()
    local path = obj:get_path("html body")
    assert.truthy(path)
    assert.truthy(#path == 1)
    assert.truthy(path[1]:is_element())
    assert.truthy(#path[1]:get_children() == 5)
  end)
 
  describe("Basic DOM traversing should work", function()
    local matched = false
    local count = 0
    obj:traverse_elements(function(el)
      count = count + 1
      if obj:get_element_name(el) == "p" then
        matched = true
        it("Element matching should work", function()
          assert.truthy(el:root_node():get_element_type() == "ROOT")
          assert.truthy(el:is_element())
          assert.truthy(el:get_element_name()== "p")
        end)
        it("Node serializing should work", function()
          local p_serialize = el:serialize()
          assert.truthy(p_serialize == "<p>nazdar</p>")
        end)
        el:remove_node(el)
      end
    end)
    it("Traverse should find 7 elements and match one <p>", function()
      assert.truthy(matched)
      assert.truthy(count == 7)
    end)
  end)

  describe("Modified DOM object serializing", function()
    local serialized = obj:serialize()
    assert.truthy(serialized)
    assert.truthy(type(serialized) == "string")
    assert.truthy(serialized:match("<html>"))
    assert.truthy(serialized:match("<p>")== nil)
  end)

  describe("CSS selector handling", function()
    local selector = "div#pokus span.ahoj, p, div.ahoj:first-child"
    local objects = obj:prepare_selector(selector)
    assert.truthy(#objects == 3)
    assert.truthy(obj:calculate_specificity(objects[1]) == 112)
    local document = [[
    <html>
    <body>
    <div class="ahoj" id="pokus">
    <span>first child</span>
    <span class="ahoj">Pokus</span>
    <p>Uff</p>
    <b>Something different</b>
    </div>
    </body>
    </html>
    ]]
    local newobj = dom.parse(document)
    local matchedlist = newobj:get_selector_path(objects)
    assert.truthy(#matchedlist == 3)
    -- assert.truthy(#obj:prepare_selector(selector)==2)
  end)


end)
