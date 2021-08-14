module juptune.commands.debug_;

import std, juptune.lua, lumars, jcli;

@Command("debug")
struct DebugCommand
{
    void onExecute()
    {
        auto l = newJuptuneState();
        l.doFile("./tests/wraps/ninja.lua");
        l.doFile("./tests/wraps/cmake.lua");
        l.doFile("./tests/wraps/llvm.lua");
        l.doFile("./tests/wraps/clang.lua");
        l.doFile("./tests/jupfile.lua");
    }
}