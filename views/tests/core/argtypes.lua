TestArgTypes = {}

function TestArgTypes:testString()
    lu.assertTrue(juptune.argtypes.string()("ABC"))
    lu.assertFalse(juptune.argtypes.string()(123))
end

function TestArgTypes:testArray()
    local isStringArray = juptune.argtypes.array(juptune.argtypes.string())
    lu.assertTrue(isStringArray({"ABC", "CDE"}))
    lu.assertFalse(isStringArray({123, 456}))
    lu.assertFalse(isStringArray("ABC"))
    lu.assertFalse(isStringArray(123))
    lu.assertTrue(isStringArray({}))
end