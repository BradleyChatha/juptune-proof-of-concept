module juptune.lua.table;

import std;
import juptune.lua, bindbc.lua;

struct LuaTable
{
    @disable this(this){}

    private
    {
        LuaState _state;
        int _ref = LUA_NOREF;
    }

    this(LuaState state, int index)
    {
        assert(state);
        this._state = state;
        
        enforce(lua_istable(state.state, index), "Element at %s on LUA stack is not a table.".format(index));
        lua_pushvalue(state.state, index);
        this._ref = luaL_ref(state.state, LUA_REGISTRYINDEX);
    }

    ~this()
    {
        luaL_unref(this._state.state, LUA_REGISTRYINDEX, this._ref);
    }

    void push()
    {
        lua_rawgeti(this._state.state, LUA_REGISTRYINDEX, this._ref);
        enforce(lua_istable(this._state.state, -1), ".push() didn't push a table. It probably pushed a nil instead.");
    }

    T get(T)(int index)
    {
        this.push();
        lua_geti(this._state.state, -1, index);
        auto value = this._state.get!T(-1);
        lua_pop(this._state.state, 2);
        return value;
    }

    T get(T)(string key)
    {
        this.push();
        this._state.push(key);
        lua_gettable(this._state.state, -2);
        auto value = this._state.get!T(-1);
        lua_pop(this._state.state, 2);
        return value;
    }
}