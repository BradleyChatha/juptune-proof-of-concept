enum("llvm-version", {"12.0.0"})
enum("llvm-install", {"compile"})

local downloadLinks = {
    ["12.0.0"] = "https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-12.0.0.zip"
}

tool({
    name = "llvm",
    description = "LLVM",
    instance_args = {
        version = juptune.argtypes.enum("llvm-version"),
        install = juptune.argtypes.enum("llvm-install"),

        cmake_verison = function(v) return true end,
        ninja_verison = function(v) return true end,
        cmake_install = function(v) return true end,
        ninja_install = function(v) return true end,
    },
    args = {},
    
    instance_configure = function(context)
        context.instance_args.cmake_version = context.cmake_version or "3.21.1"
        context.instance_args.ninja_version = context.ninja_version or "1.10.2"
        context.instance_args.cmake_install = context.cmake_install or "download"
        context.instance_args.ninja_install = context.ninja_install or "download"
        if context.instance_args.install == "compile" then
            context.config.llvm_path = juptune.path.getToolPath("llvm", { version = context.instance_args.version })
        end
    end,

    dependencies = function(context)
        local deps = {
            tools = {}
        }

        if context.instance_args.install == "compile" then
            deps.tools = {
                {
                    name = "cmake",
                    install = context.instance_args.cmake_install,
                    version = context.instance_args.cmake_version,
                    generators = {"Ninja"},
                    build_dir = juptune.path.build({context.config.llvm_path, "build"}),
                    source_dir = "../llvm"
                },
                {
                    name = "ninja",
                    install = context.instance_args.ninja_install,
                    version = context.instance_args.ninja_version,
                    working_dir = juptune.path.build({context.config.llvm_path, "build"})
                }
            }
        end

        return deps
    end,

    detect = function(context)
        -- return string.match(
        --     juptune.io.execute(
        --         context.config.clang_path,
        --         {"--version"}
        --     ),
        --     "clang version "..context.instance_args.version
        -- )

        -- Unfortunately my computer's C++ environment is completely fucked (thanks Visual Studio) so I can't build
        -- LLVM, so it'll just have to assume that clang is already installed.
        return true
    end,

    install = function(context)
        if context.instance_args.install == "compile" then
            local link = downloadLinks[context.instance_args.version]
            local zip = juptune.io.downloadTemp(link)
            local zip = "./temp"
            local out = context.config.llvm_path
            juptune.io.ensureDir(out)
            juptune.io.unzip(zip, out)
            local p = juptune.io.matchFirst(out, "llvm")
            juptune.io.unnestDir(p)
            
            context.tools.cmake({
                generator = "Ninja",
                build_dir = juptune.path.build({context.config.llvm_path, "build/"}),
                defines = {
                    CMAKE_BUILD_TYPE = "Release"
                }
            })

            context.tools.ninja({
                target = "",
                working_dir = juptune.path.build({context.config.llvm_path, "build/"})
            })
        end
    end
})

local i = juptune.tools.resolve("llvm", {
    version = "12.0.0",
    install = "compile",
    cmake_verison = nil,
    cmake_install = nil,
    ninja_version = nil,
    ninja_install = nil,
});