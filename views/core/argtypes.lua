juptune          = juptune or {}
juptune.argtypes = juptune.argtypes or {}

function juptune.argtypes.string()
    return function(value) return type(value) == "string" end
end

function juptune.argtypes.array(argtype)
    return function(value)
        if type(value) ~= "table" then return false end
        return juptune.alg.all(value, function(v) return argtype(v) end)
    end
end

function juptune.argtypes.enum(enumName)
    return function(value)
        return juptune.enums._validate(enumName, value)
    end
end

function juptune.argtypes.map(keyarg, valuearg)
    return function(value)
        if type(value) ~= "table" then return false end
        for k, v in pairs(value) do
            if not keyarg(k) then return false end
            if not valuearg(v) then return false end
        end
        return true
    end
end

function juptune.argtypes.validate(name, argtype, value)
    if not argtype(value) then
        error(inspect({name, argtype, value}))
    end
end
