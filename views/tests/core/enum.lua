TestEnum = {}

function TestEnum:testEnum()
    enum("test", {"1", "2", "3"})
    lu.assertTrue(juptune.enums._validate("test", "1"))
    lu.assertFalse(juptune.enums._validate("test", "20"))
end