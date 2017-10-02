require "busted.runner" ()
kpse.set_program_name "luatex"
local mkparams = require "mkparams"

describe("Test output format and extensions", function()
  it("Should parse the output formats", function()
    local format, extensions = mkparams.get_format_extensions("html5+latexmk+sample-disabled")
    assert.are.equal(format, "html5")
    assert.are.equal(type(extensions), "table")
    assert.are.equal(#extensions, 3)
    assert.are.equal(extensions[2].name, "sample")
    assert.are.equal(extensions[3].type, "-")
  end)
end)
