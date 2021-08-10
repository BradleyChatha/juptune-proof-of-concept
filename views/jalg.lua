juptune.alg = juptune.alg or {}

function juptune.alg.map(source, func)
    local result = {}

    for i, value in ipairs(source) do
        result[i] = func(value)
    end

    return result
end

function juptune.alg.merge(a, b)
    for k,v in pairs(b) do a[k] = v end
    return a
end