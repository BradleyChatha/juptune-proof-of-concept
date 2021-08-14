TestAlg = {}

function TestAlg:testAll()
    local values = { 2, 4, 6 }
    lu.assertTrue(juptune.alg.all(values, function(v) return v % 2 == 0 end))
    lu.assertFalse(juptune.alg.all(values, function(v) return v % 2 == 1 end))
end

function TestAlg:testCanFind()
    local values = { "1", 2 }
    lu.assertTrue(juptune.alg.canFind(values, "1", function(n, v) return v == n end))
    lu.assertTrue(juptune.alg.canFind(values, 2, function(n, v) return v == n end))
    lu.assertFalse(juptune.alg.canFind(values, 1, function(n, v) return v == n end))
    lu.assertFalse(juptune.alg.canFind(values, "2", function(n, v) return v == n end))
end

function TestAlg:testAllowFields()
    local obj = {
        a = "b"
    }
    juptune.alg.allowFields({"a"}, obj)
end