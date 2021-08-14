juptune         = juptune or {}
juptune.alg     = juptune.alg or {}

function juptune.alg.all(value, func)
    for k, v in pairs(value) do
        if not func(v) then return false end
    end
    return true
end

function juptune.alg.canFind(haystack, needle, func)
    for k, v in pairs(haystack) do
        if func(needle, v) then return true end
    end
    return false
end

function juptune.alg.allowFields(fieldNames, obj)
    local allowed = {}
    for i, v in ipairs(fieldNames) do
        allowed[v] = false;
    end

    for k, v in pairs(obj) do
        if allowed[k] == nil then
            error("Unexpected field called '"..k.."'")
        end

        if allowed[k] then
            error("Duplicate field called '"..k.."'")
        end

        allowed[k] = true
    end
end