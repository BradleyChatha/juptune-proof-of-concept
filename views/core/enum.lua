juptune         = juptune or {}
juptune.enums   = juptune.enums or {}

function enum(name, values)
    juptune.argtypes.validate("name", juptune.argtypes.string(), name)
    juptune.argtypes.validate("values", juptune.argtypes.array(juptune.argtypes.string()), values)

    if juptune.enums[name] then
        error("An enum called '"..name.."' already exists")
    end

    juptune.enums[name] = values
end

function juptune.enums._validate(enumName, value)
    juptune.argtypes.validate("enumName", juptune.argtypes.string(), enumName)
    juptune.argtypes.validate("value", juptune.argtypes.string(), value)

    if not juptune.enums[enumName] then
        error("No enum called '"..enumName.."' exists")
    end

    return juptune.alg.canFind(juptune.enums[enumName], value, function(n, v) return n == v end)
end