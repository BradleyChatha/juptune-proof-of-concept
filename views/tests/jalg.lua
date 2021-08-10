TestAlg = {}

function TestAlg:testMap()
    local before = {1, 2, 3, 4, 5}
    local after  = {2, 4, 6, 8, 10}
    local got    = juptune.alg.map(before, function(i) return i * 2 end)
    lu.assertEquals(got, after)
end

return lu.LuaUnit.run()