module juptune.lua.japi.files;

import std, juptune.lua, sdlite, bindbc.lua;

struct FileCache
{
    static struct Info
    {
        string path;
        uint metadataHash;
        ulong lastModified;
    }

    private
    {
        SDLNode         _node;
        Info[string]    _info; // Key is Info.Path
    }

    this(bool _)
    {
        // To keep things simple for now, we'll just use the curr dir as the root.
        if(!exists(".juptune"))
            mkdir(".juptune");
        
        if(exists(".juptune/deps.sdl"))
        {
            parseSDLDocument!(n => _node.children ~= n)(readText(".juptune/deps.sdl"), ".juptune/deps.sdl");
            foreach(node; this._node.children)
            {
                enforce(node.name == "file");
                Info i;
                i.path = node.values[0].textValue;
                i.metadataHash = node.getAttribute("metadata_hash").intValue;
                i.lastModified = node.getAttribute("last_modified").longValue;
                _info[i.path] = i;
            }
        }
    }

    void update(string path, uint metadataHash)
    {
        enforce(path.exists, "File does not exist: "~path);
        const lastUpdate = timeLastModified(path);

        scope ptr = (path in this._info);
        if(!ptr)
        {
            this._info[path] = Info.init;
            ptr = path in this._info;
        }

        ptr.metadataHash = metadataHash;
        ptr.lastModified = lastUpdate.stdTime;
    }

    bool isFileOutOfDate(string path, uint metadataHash)
    {
        if((path in this._info) is null)
            return true;

        if(timeLastModified(path).stdTime != this._info[path].lastModified)
            return true;

        if(metadataHash != this._info[path].metadataHash)
            return true;

        return false;
    }
}

FileCache g_fileCache; // Makes it a lot easier to work with LUA. I will eventually need to move it to a context thing though...

void openJuptuneFiles(LuaState lua)
{
    g_fileCache = FileCache(false); // Again, this is temporary
    lua.register!(
        "isOutOfDate",  luaBasicCWrapper!isOutOfDate,
        "update",       luaBasicCWrapper!update
    )("tempF");
    lua.doString(`
        juptune.files                   = juptune.files or {}
        juptune.files.isOutOfDateImpl   = tempF.isOutOfDate
        juptune.files.updateImpl        = tempF.update
    `);
    lua.doString(import("jfiles.lua"));
}

int isOutOfDate(LuaState lua)
{
    luaL_checktype(lua.state, 1, LUA_TSTRING);
    luaL_checktype(lua.state, 2, LUA_TNUMBER);
    lua_pushboolean(lua.state, g_fileCache.isFileOutOfDate(lua.get!string(1), lua.get!uint(2)));

    return 1;
}

int update(LuaState lua)
{
    luaL_checktype(lua.state, 1, LUA_TSTRING);
    luaL_checktype(lua.state, 2, LUA_TNUMBER);
    g_fileCache.update(lua.get!string(1), lua.get!uint(2));

    return 0;
}