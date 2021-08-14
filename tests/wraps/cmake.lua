enum("cmake-version", {"3.21.1"})
enum("cmake-install", {"download"})
enum("cmake-generator", {"Ninja"})

local downloadLinks = {
    windows = {
        ["3.21.1"] = "https://github.com/Kitware/CMake/releases/download/v3.21.1/cmake-3.21.1-windows-x86_64.zip"
    }
}

tool({
    name = "cmake",
    description = "CMake",
    instance_args = {
        version    = juptune.argtypes.enum("cmake-version"),
        install    = juptune.argtypes.enum("cmake-install"),
        generators = juptune.argtypes.array(juptune.argtypes.enum("cmake-generator")),
        build_dir  = juptune.argtypes.string(),
        source_dir = juptune.argtypes.string()
    },
    args = {
        generator = juptune.argtypes.enum("cmake-generator"),
        defines   = juptune.argtypes.map(juptune.argtypes.string(), juptune.argtypes.string()),
    },

    instance_configure = function(context)
        if context.instance_args.install == "download" then
            context.config.cmake_path = juptune.path.build({
                juptune.path.getToolPath("cmake", { version = context.instance_args.version }),
                "bin/",
                "cmake"
            })
        end

        if not juptune.path.isAbsolute(context.instance_args.build_dir) then
            context.config.build_dir = juptune.path.build({
                juptune.path.projectPath(),
                context.instance_args.build_dir
            })
        else
            context.config.build_dir = context.instance_args.build_dir
        end
    end,

    dependencies = function(context) 
        local deps = {
            tools = {}
        }
        
        for i, v in ipairs(context.instance_args.generators) do
            if v == "Ninja" then
                table.insert(deps.tools, { name = "ninja", version = "1.10.2", install = context.instance_args.install, working_dir = context.instance_args.build_dir })
            end
        end

        return deps
    end,

    detect = function(context) 
        return string.match(
            juptune.io.execute(
                context.config.cmake_path, 
                {"--version"}
            ), 
            "."
        )
    end,
    
    install = function(context) 
        if context.instance_args.install == "download" then
            if juptune.platform.name() == "windows" then
                local link = downloadLinks.windows[context.instance_args.version]
                local zip = juptune.io.downloadTemp(link)
                local zip = "./temp"
                local out = juptune.path.getToolPath("cmake", { version = context.instance_args.version })
                juptune.io.ensureDir(out)
                juptune.io.unzip(zip, out)

                local topLevel = juptune.io.matchFirst(out, "cmake")
                juptune.io.unnestDir(topLevel)
            else
                error("Don't know how to install CMake on this platform.")
            end
        end
    end,

    run = function(context)
        juptune.io.ensureDir(context.config.build_dir)
        juptune.io.cd(context.config.build_dir)

        local args = {}
        table.insert(args, "-G "..context.args.generator)

        for k, v in pairs(context.args.defines) do
            table.insert(args, "-D"..k.."="..v)
        end
        table.insert(args, context.instance_args.source_dir)

        print(juptune.io.execute(
            context.config.cmake_path,
            args
        ))
    end,
})