module juptune.lua.japi.alg;

import juptune.lua;

void openJuptuneAlg(LuaState lua)
{
    lua.doString(import("jalg.lua"));
}

unittest
{
    auto lua = newJuptuneLua();
    lua.doString(import("tests/jalg.lua"));
    assert(lua.get!int(-1) == 0);
}