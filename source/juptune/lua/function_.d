module juptune.lua.function_;

import std;
import juptune.lua, bindbc.lua;

int luaBasicCWrapper(alias Func)(lua_State* state) nothrow
{
    try
    {
        scope wrapper = new LuaState(state);
        return Func(wrapper);
    }
    catch(Throwable t) // We're in a LUA stack frame, so this is needed
        return luaL_error(state, "[%s:%d] %s", t.file.ptr, t.line, t.msg.toStringz);
}