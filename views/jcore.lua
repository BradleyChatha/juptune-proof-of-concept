juptune.core = juptune.core or {}

juptune.core.Args = { validators = {} }
juptune.core.Args.prototype = {}
juptune.core.Args.prototype.__index = juptune.core.Args.prototype

juptune.tools = {}
juptune.stages = {}
juptune.pipelines = {}
juptune.toolchains = {}

juptune.tools.prototype = {}
juptune.stages.prototype = {}
juptune.pipelines.prototype = {}

juptune.tools.prototype.__call = function(self, args)
    print("\t\tRunning tool: "..self.name)

    for k, v in pairs(args) do
        if type(v) == "function" then
            args[k] = v()
        end
    end

    if self.argToShowUser then
        local arg = inspect(args[self.argToShowUser])
        string.gsub(arg, "^.+$", function(s) print("\t\t\t" .. arg) end)
    end
    return self.func(juptune.core.Args.new(args)) 
end
juptune.stages.prototype.__call = function(self, args)
    print("\tRunning stage: "..self.name)
    for k, v in pairs(args) do
        if type(v) == "function" then
            args[k] = v()
        end
    end
    return self.func(juptune.core.Args.new(args)) 
end
juptune.pipelines.prototype.__call = function(self, args)
    print("Running pipeline: "..self.name)
    for k, v in pairs(args) do
        if type(v) == "function" then
            args[k] = v()
        end
    end
    self.returned.returnValue = self.func(juptune.core.Args.new(args))
    return self.returned.returnValue
end

function juptune.core.Args.new(args)
    setmetatable(args, juptune.core.Args.prototype)
    return args
end

function juptune.core.Args.addValidator(key, validator)
    assert(type(validator) == "function", "validator must be a function")
    assert(type(key) == "string", "key must be a string")
    assert(not juptune.core.Args.validators[key], "key already exists: "..key)

    juptune.core.Args.validators[key] = validator
end

function juptune.core.Args.prototype:expect(key, t)
    local value = self[key]
    if string.match(t, "_array$") and type(value) ~= "table" then
        value = {value}
    end
    if value == nil then
        error("Expected argument called "..key.." but it wasn't provided.")
    end
    if not juptune.core.Args.validators[t](value) then
        error("Expected argument "..key.." to be of type "..t)
    end
    return value
end

function juptune.core.Args.prototype:maybe(key, t)
    local value = self[key]
    if string.match(t, "_array$") and type(value) ~= "table" then
        value = {value}
    end
    if value == nil then return nil end
    if not juptune.core.Args.validators[t](value) then
        error("Expected optional argument "..key.." to be of type "..t)
    end
    return value
end

function _G.tool(name, obj)
    setmetatable(obj, juptune.tools.prototype)
    obj.name = name
    juptune.tools[name] = obj
end

function _G.stage(name, obj)
    setmetatable(obj, juptune.stages.prototype)
    obj.name = name
    juptune.stages[name] = obj
end

function _G.pipeline(name, obj)
    setmetatable(obj, juptune.pipelines.prototype)
    obj.name = name
    obj.returned = {}
    juptune.pipelines[name] = obj
end

function _G.toolchain(name, data)
    data.name = name
    juptune.toolchains[name] = data
end

function juptune.core.getPipelineReturnVar(path)
    local results = {}
    string.gsub(path, "[^:]+", function(s) table.insert(results, s) end)
    assert(#results >= 2, "Expected at least one ':' within variable path.")

    local pipeline = juptune.pipelines[results[1]]
    local ret      = pipeline.returned

    if results[2] == "return" then return ret.returnValue end

    for i, key in ipairs(results) do
        if i >= 2 then
            ret = ret[key]
        end
    end

    return ret
end

function juptune.toolchains.__execute(toolchain)
    local tc = juptune.toolchains[toolchain]
    
    for i, v in ipairs(tc.pipelines) do
        if v.__pipeline then
            pipe = juptune.pipelines[v.__pipeline]
            pipe(v)
        elseif v.__export then
            pipe.returned[v.to] = juptune.core.getPipelineReturnVar(pipe.name..":"..v.__export)
            print(inspect(pipe))
        end
    end
end

juptune.core.Args.addValidator("string", function(s) return type(s) == "string" end)
juptune.core.Args.addValidator("string_array", function(s)
    if type(s) ~= "table" then return false end
    return true
end)