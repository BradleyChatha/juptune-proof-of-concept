module juptune.lua.japi.core;

import std;
import juptune.lua, bindbc.lua;

LuaState newJuptuneLua()
{
    auto l = new LuaState();
    openJuptune(l);
    return l;
}

void openJuptune(LuaState lua)
{
    lua.register!(
        "printStack",   luaBasicCWrapper!printStack,
        "hashOfTable",  luaBasicCWrapper!hashOfTable,
    )("juptune");

    addEnv(lua);

    lua.doString(import("inspect.lua"));
    version(unittest) lua.doString(import("luaunit.lua"));
    lua.doString(import("jcore.lua"));

    openJuptunePath(lua);
    openJuptuneAlg(lua);
    openJuptuneFiles(lua);
    openJuptuneShell(lua);
}

int hashOfTable(LuaState lua)
{
    luaL_checktype(lua.state, 1, LUA_TTABLE);
    lua_pushnumber(lua.state, cast(lua_Number)hashLuaTable(lua, 1));
    return 1;
}

unittest
{
    auto lua = newJuptuneLua();
    lua.doString(import("tests/jcore.lua"));
    assert(lua.get!int(-1) == 0);
}

void addEnv(LuaState lua)
{
    lua_getglobal(lua.state, "juptune");
    lua_pushstring(lua.state, "env");
    lua_newtable(lua.state);

    foreach(k, v; environment.toAA())
    {
        lua.push(k);
        lua.push(v);
        lua_rawset(lua.state, -3);
    }
    lua_rawset(lua.state, -3);
}