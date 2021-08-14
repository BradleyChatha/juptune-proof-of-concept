enum("clang-version", {"12.0.0"})
enum("clang-install", {"compile"})

tool({
    name = "clang",
    description = "clang",
    instance_args = {
        version    = juptune.argtypes.enum("clang-version"),
        install    = juptune.argtypes.enum("clang-install"),
    },
    args = {
        sources = juptune.argtypes.array(juptune.argtypes.string()),
        output = juptune.argtypes.string(),
        include = juptune.argtypes.string()
    },

    instance_configure = function(context)
    end,

    dependencies = function(context) 
        local deps = {
            tools = {
                {
                    name = "llvm",
                    version = context.instance_args.version,
                    install = context.instance_args.install
                }
            }
        }

        return deps
    end,

    detect = function(context) 
        -- Because I can't compile LLVM, we'll just assume it's in the PATH
        return true
    end,
    
    install = function(context) 
        -- ditto
    end,

    run = function(context)
        -- NOT IMPLEMENTED
        -- if juptune.files.isOutOfDate(context.args.sources) then
        -- juptune.files.updateDependencies(context.args.sources)

        juptune.io.cd(juptune.path.projectPath())
        local args = 
        {
            "-o "..context.args.output,
            "-I "..context.args.include,
        }

        for i, v in ipairs(context.args.sources) do 
            table.insert(args, v)
        end

        print(juptune.io.execute(
            "clang",
            args
        ))
        
        -- juptune.files.updateDependencies({ context.args.output })
        -- end
    end,
})