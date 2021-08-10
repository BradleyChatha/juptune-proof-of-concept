module juptune.lua.state;

import std;
import bindbc.lua;

enum LuaType
{
    str = LUA_TSTRING,
    num = LUA_TNUMBER,
    bol = LUA_TBOOLEAN,
    tab = LUA_TTABLE
}

final class LuaState
{
    private
    {
        lua_State* _state;
        bool _isWrapper;
    }

    this()
    {
        this._state = luaL_newstate();
        luaL_openlibs(this._state);
    }

    this(lua_State* wrap)
    {
        this._state = wrap;
        this._isWrapper = true;
    }

    ~this()
    {
        if(this._state && !this._isWrapper)
            lua_close(this._state);
    }

    void doString(string str)
    {
        const wasError = luaL_dostring(this._state, str.toStringz) != 0;

        if(wasError)
        {
            const error = this.get!string(-1);
            this.pop(1);
            throw new Exception(error);
        }
    }

    void pcall(int nargs, int nresults, int errorfunc = 0)
    {
        const result = lua_pcall(this._state, nargs, nresults, errorfunc);
        if(result != 0)
        {
            const error = this.get!string(-1);
            this.pop(1);
            throw new Exception(error);
        }
    }

    void push(T)(T value)
    {
        static if(is(T : const(char)[]))
            lua_pushlstring(this.state, value.ptr, value.length);
        else static if(is(T : lua_CFunction))
            lua_pushcfunction(this._state, &value);
        else static assert(false, "Don't know how to push: "~T.stringof);
    }

    void pop(int amount)
    {
        lua_pop(this._state, amount);
    }

    LuaType type(int index)
    {
        return lua_type(this.state, index).to!LuaType;
    }

    T get(T)(int stackIndex)
    {
        static if(is(T == string))
        {
            enforce(lua_isstring(this._state, stackIndex), "Element at %s on LUA stack is not a string.".format(stackIndex));
            auto value = lua_tostring(this._state, stackIndex).fromStringz.idup;
            return value;
        }
        else static if(isNumeric!T)
        {
            enforce(lua_isnumber(this._state, stackIndex), "Element at %s on LUA stack is not a number.".format(stackIndex));
            return cast(T)lua_tonumber(this._state, stackIndex);
        }
        else static if(is(T == bool))
        {
            enforce(lua_isboolean(this._state, stackIndex), "Element at %s on LUA stack is not a boolean.".format(stackIndex));
            return cast(bool)lua_toboolean(this._state, stackIndex);
        }
        else static assert(false, "Don't know how to convert any LUA values into: "~T.stringof);
    }

    void register(Args...)(string name)
    if(Args.length % 2 == 0)
    {
        luaL_Reg[(Args.length/2) + 1] regs;
        static foreach(i; 0..Args.length/2)
            regs[i] = luaL_Reg(Args[i*2].toStringz, &Args[(i*2)+1]);
        regs[$-1] = luaL_Reg(null, null);
        luaL_register(this._state, name.toStringz, &regs[0]);
        this.pop(1);
    }

    lua_State* state()
    {
        return this._state;
    }
}