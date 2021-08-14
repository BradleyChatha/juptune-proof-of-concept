enum("ninja-version", {"1.10.2"})
enum("ninja-install", {"download"})

local downloadLinks = {
    windows = {
        ["1.10.2"] = "https://github.com/ninja-build/ninja/releases/download/v1.10.2/ninja-win.zip"
    }
}

tool({
    name = "ninja",
    description = "Ninja",
    instance_args = {
        version     = juptune.argtypes.enum("ninja-version"),
        install     = juptune.argtypes.enum("ninja-install"),
        working_dir = juptune.argtypes.string()
    },
    args = {
        target      = juptune.argtypes.string(),
    },

    instance_configure = function(context)
        if context.instance_args.install == "download" then
            context.config.ninja_path = juptune.path.build({
                juptune.path.getToolPath("ninja", { version = context.instance_args.version }),
                "ninja"
            })
        end

        if not juptune.path.isAbsolute(context.instance_args.working_dir) then
            context.config.working_dir = juptune.path.build({
                juptune.path.projectPath(),
                context.instance_args.working_dir
            })
        else
            context.config.working_dir = context.instance_args.working_dir
        end
    end,

    dependencies = function(context) end,

    detect = function(context)
        return string.match(
            juptune.io.execute(
                context.config.ninja_path, 
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
                local out = juptune.path.getToolPath("ninja", { version = context.instance_args.version })
                juptune.io.ensureDir(out)
                juptune.io.unzip(zip, out)
            else
                error("Don't know how to install Ninja on this platform.")
            end
        end
    end,

    run = function(context)
        juptune.io.ensureDir(context.config.working_dir)
        juptune.io.cd(context.config.working_dir)
        print(juptune.io.execute(
            context.config.ninja_path,
            {
            }
        ))
    end,
})