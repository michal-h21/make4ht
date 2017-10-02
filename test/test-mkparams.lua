require "busted.runner" ()
kpse.set_program_name "luatex"
local mkparams = require "mkparams"

describe("Test output format and extensions", function()
  it("Should parse the output formats", function()
    local format, extensions = mkparams.get_format_extensions("html5+latexmk")
    assert.are.equal(format, "html5")
  end)
end)
