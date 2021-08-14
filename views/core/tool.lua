juptune                 = juptune or {}
juptune.tools           = juptune.tools or {}
juptune.tools.template  = juptune.tools.template or {}
juptune.tools.instances = juptune.tools.instances or {}

function tool(obj)
    juptune.alg.allowFields({
        "name",                 "description",
        "instance_args",        "args",
        "instance_configure",   "dependencies",
        "install",              "run",
        "detect",
    }, obj)

    if not obj.name then error("The 'name' field is required for tools.") end
    if not obj.detect then error("The 'detect' field is required for tools.") end

    if juptune.tools.template[obj.name] then
        error("Tool called '"..obj.name.."' already exists")
    end

    juptune.tools.template[obj.name] = obj
end

local function _validateArgs(template, instanceArgs)
    juptune.io.print("Validating arguments")
    template.instance_args = template.instance_args or {}

    local instanceArgNames = {}
    for k, v in pairs(template.instance_args) do
        table.insert(instanceArgNames, k)
    end
    juptune.alg.allowFields(instanceArgNames, instanceArgs)

    for k, v in pairs(template.instance_args) do
        juptune.argtypes.validate(k, v, instanceArgs[k])
    end
end

local function _createInstance(template, instanceArgs)
    juptune.io.print("Creating instance")
    return {
        context = {
            instance_args = instanceArgs,
            config = {},
            tools = {},
        },

        instance_configure = template.instance_configure or function() end,
        dependencies = template.dependencies or function() end,
        detect = template.detect,
        install = template.install or function() end,
        run = template.run or function() end,
    }
end

local function _loadDeps(instance)
    juptune.io.print("Loading dependencies")
    juptune.io.entab()

    local deps = instance.dependencies(instance.context)
    if not deps then
        juptune.io.detab()
        return 
    end

    if deps.tools then
        for i, v in ipairs(deps.tools) do
            local name = v.name
            local args = {}
            for k, value in pairs(v) do
                if k ~= "name" then args[k] = value end
            end
            instance.context.tools[name] = juptune.tools.resolve(name, args)
        end
    end

    juptune.io.detab()
end

local function _detectInstall(instance)
    juptune.io.print("Detecting")
    juptune.io.entab()

    if not instance.detect(instance.context) then
        juptune.io.print("Could not detect, calling .install")
        instance.install(instance.context)

        if not instance.detect(instance.context) then
            error("Still unable to detect tool even after a call to .install")
        end
    end

    juptune.io.print("Tool detected/installed")
    juptune.io.detab()
end

function juptune.tools.resolve(toolName, instanceArgs)
    juptune.io.printPrefixed("Resolving", toolName)
    juptune.io.entab()
    
    local hash = toolName..hashOf(instanceArgs)
    if juptune.tools.instances[hash] then
        juptune.io.print("Hash found, returning cached instance")
        juptune.io.detab()
        return juptune.tools.instances[hash]
    end
    juptune.io.print("Hash not found, continuing to resolve")

    local template = juptune.tools.template[toolName];
    if not template then error("No tool called '"..toolName.."' exists") end

    _validateArgs(template, instanceArgs)

    local instance = _createInstance(template, instanceArgs)
    instance.instance_configure(instance.context)
    _loadDeps(instance)
    _detectInstall(instance)

    juptune.tools.instances[hash] = instance
    setmetatable(instance, {
        __call = function(self, obj)
            self.context.args = obj or {}
            self.run(self.context)
        end
    })
    juptune.io.detab()

    return instance
end