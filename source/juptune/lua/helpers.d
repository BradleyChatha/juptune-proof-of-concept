module juptune.lua.helpers;

import juptune.lua, bindbc.lua, std;

int printStack(LuaState lua)
{
    const elements = lua_gettop(lua.state);
    if(elements == 0)
    {
        writeln("NO VALUES ON STACK");
        return 0;
    }

    writeln("LUA STACK TRACE:");
    foreach(i; 1..elements+1)
    {
        writef("[-%s] ", i);
        const type = lua_type(lua.state, i * -1);
        switch(type)
        {
            case LUA_TSTRING:
                writeln("\tSTR\t", lua.get!string(i * -1));
                break;

            case LUA_TNUMBER:
                writeln("\tNUM\t", lua.get!double(i * -1), " OR AS INT ", lua.get!long(i * -1));
                break;

            default:
                writeln("\tUNKW\t", type);
                break;
        }
    }
    return 0;
}

uint hashLuaTable(LuaState lua, int tableIndex)
{
    import juptune.misc.murmur3;

    Murmur3_32 hash;

    void hashTable(int idx)
    {
        lua_pushnil(lua.state);
        while(lua_next(lua.state, idx) != 0)
        {
            // Hash the key
            if(lua_isnumber(lua.state, -2))
            {
                const value = lua.get!long(-2);
                hash.put((&value)[0..1]);
            }
            else
                hash.put(lua.get!string(-2));

            // Then the value
            switch(lua_type(lua.state, -1))
            {
                case LUA_TBOOLEAN:
                    const value = lua_toboolean(lua.state, -1);
                    hash.put((&value)[0..1]);
                    break;

                case LUA_TNUMBER:
                    const value = lua_tonumber(lua.state, -1);
                    hash.put((&value)[0..1]);
                    break;

                case LUA_TSTRING:
                    const value = lua.get!string(-1);
                    hash.put(value);
                    break;

                case LUA_TTABLE:
                    hashTable(-2);
                    break;

                default: break;
            }

            // Pop the value
            lua.pop(1);
        }
    }

    hashTable(tableIndex);
    return hash.value;
}