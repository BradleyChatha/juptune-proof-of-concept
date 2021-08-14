-- NOT IMPLEMENTED
-- add_wrap_repo({
--     type = "local",
--     uri = "./wraps"
-- })

local clang = juptune.tools.resolve("clang", { version = "12.0.0", install = "compile" })

-- In a serious implementation we'd automatically make these paths relative to the .lua file
-- But this is just hacked together
local sources = {
    juptune.path.build({juptune.path.projectPath(), "tests/01-basic/src/app.c"}),
    juptune.path.build({juptune.path.projectPath(), "tests/01-basic/src/lib.c"}),
}

local include = juptune.path.build({juptune.path.projectPath(), "tests/01-basic/include"})
local output = juptune.path.build({juptune.path.projectPath(), "tests/01-basic/bin/test.exe"})

clang({
    sources = sources,
    include = include,
    output = output
})