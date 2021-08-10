TestPath = {}

function TestPath:testSetExt()
    local before = "abc.one"
    local after  = "abc.two"
    local got    = juptune.path.setExt(before, ".two")
    lu.assertEquals(got, after)
end

function TestPath:testSetExtNull()
    local before = "abc.one"
    local after  = "abc"
    local got    = juptune.path.setExt(before, nil)
    lu.assertEquals(got, after)
end

function TestPath:testFilename()
    local before = "one/two/three.abc"
    local after  = "three.abc"
    local got    = juptune.path.fileName(before)
    lu.assertEquals(got, after)
end

return lu.LuaUnit.run()