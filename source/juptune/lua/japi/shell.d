module juptune.lua.japi.shell;

import juptune.lua, std, bindbc.lua;

void openJuptuneShell(LuaState lua)
{
    lua.register!(
        "execExpectStatus", luaBasicCWrapper!execExpectStatus,
    )("tempS");
    lua.doString(`
        juptune.shell                   = juptune.shell or {}
        juptune.shell.execExpectStatus  = tempS.execExpectStatus
    `);
    lua.doString(import("jshell.lua"));
}

int execExpectStatus(LuaState lua)
{
    luaL_checktype(lua.state, 1, LUA_TSTRING);
    luaL_checktype(lua.state, 2, LUA_TNUMBER);
    luaL_checktype(lua.state, 3, LUA_TSTRING);
    writeln("\t\t\tExecuting: ", lua.get!string(1));
    auto result = executeShell(lua.get!string(1));
    if(result.status != lua.get!int(2))
        return luaL_error(lua.state, "Expected command to return %d, not %d: %s\n%s", lua.get!int(2), result.status, lua_tostring(lua.state, 3), result.output.toStringz);

    return 0;
}