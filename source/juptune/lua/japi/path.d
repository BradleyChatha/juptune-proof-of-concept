module juptune.lua.japi.path;

import std, juptune.lua, bindbc.lua;

void openJuptunePath(LuaState lua)
{
    lua.register!(
        "setExt",         luaBasicCWrapper!setExt,
        "fileName",       luaBasicCWrapper!fileName,
        "ensureDir",      luaBasicCWrapper!ensureDir
    )("tempP");
    lua.doString(`
        juptune.path            = juptune.path or {}
        juptune.path.setExt     = tempP.setExt
        juptune.path.fileName   = tempP.fileName
        juptune.path.ensureDir  = tempP.ensureDir
    `);
}

int setExt(LuaState lua)
{
    luaL_checktype(lua.state, 1, LUA_TSTRING);

    const path = lua.get!string(1);
    
    if(lua_isstring(lua.state, 2))
        lua.push(setExtension(path, lua.get!string(2)));
    else
        lua.push(setExtension(path, ""));

    return 1;
}

int fileName(LuaState lua)
{
    luaL_checktype(lua.state, 1, LUA_TSTRING);

    const path = lua.get!string(1);
    lua.push(baseName(path));

    return 1;
}

int ensureDir(LuaState lua)
{
    luaL_checktype(lua.state, 1, LUA_TSTRING);
    
    const path = lua.get!string(1).dirName;
    if(!exists(path))
        mkdirRecurse(path);

    return 0;
}

unittest
{
    auto lua = newJuptuneLua();
    lua.doString(import("tests/jpath.lua"));
    assert(lua.get!int(-1) == 0);
}