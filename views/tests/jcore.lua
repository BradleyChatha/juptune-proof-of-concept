TestCore = {}

function TestCore:testArgs()
    local args = juptune.core.Args.new({
        str = "hello"
    })
    lu.assertEquals(args:expect("str", "string"), "hello")
    lu.assertEquals(args:maybe("str", "string"), "hello")
    lu.assertEquals(args:maybe("bad", "brad"), nil)
end

function TestCore:testStages()
    tool("test", {
        func = function(args)
            lu.assertEquals(args:expect("value", "string"), "hello")
        end
    })
    stage("test", {
        func = function(args)
            lu.assertEquals(args:expect("value", "string"), "hello")
        end
    })
    pipeline("test", {
        func = function(args)
            lu.assertEquals(args:expect("value", "string"), "hello")
            return {one = {two = {three = "nani"}}}
        end
    })
    juptune.tools.test({value = "hello"})
    juptune.stages.test({value = "hello"})
    juptune.pipelines.test({value = "hello"})
    lu.assertEquals(juptune.core.getPipelineReturnVar("test:one:two:three"), "nani")
end

return lu.LuaUnit.run()