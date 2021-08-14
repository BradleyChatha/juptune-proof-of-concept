module juptune.lua;

import std, lumars, jansi, vibe.inet.urltransfer : download;

LuaState* newJuptuneState()
{
    auto l = new LuaState(null);
    l.doString(import("third/inspect.lua"));
    l.register!hashLuaTable("hashOf");

    l.register!(
        "print",            print,
        "printPrefixed",    printPrefixed,
        "entab",            entab,
        "detab",            detab,
        "execute",          execute,
        "downloadTemp",     downloadTemp,
        "ensureDir",        ensureDir,
        "unzip",            unzip,
        "matchFirst",       matchFirst,
        "unnestDir",        unnestDir,
        "cd",               cd
    )("_tempio");
    l.doString(`
        juptune = juptune or {}
        juptune.io = _tempio
        _tempio = nil
    `);

    l.register!(
        "build",        (string[] paths) => paths.buildPath.absolutePath,
        "getToolPath",  getToolPath,
        "isAbsolute",   isAbsolute!string,
        "projectPath",  projectPath
    )("_temppath");
    l.doString(`
        juptune = juptune or {}
        juptune.path = _temppath
        _temppath = nil
    `);
    
    l.register!(
        "name",         platformName
    )("_tempplat");
    l.doString(`
        juptune = juptune or {}
        juptune.platform = _tempplat
        _tempplat = nil
    `);

    version(unittest) l.doString(import("third/luaunit.lua"));
    static foreach(file; [
        "core/alg.lua",
        "core/argtypes.lua",
        "core/enum.lua",
        "core/tool.lua"
    ])
    {
        l.doString(import(file));
        version(unittest) l.doString(import("tests/"~file));
    }

    return l;
}

unittest
{
    auto l = newJuptuneState();
    l.doString(`
        if lu.LuaUnit.run() ~= 0 then
            error("Not all LUA tests passed.")
        end
    `);
}

// juptune.io
private
{
    uint g_tabCount;

    void printTabs()
    {
        foreach(i; 0..g_tabCount)
            write("    ");
    }

    void print(string value)
    {
        printTabs();
        writeln(value);
    }

    void printPrefixed(string prefix, string value)
    {
        printTabs();
        writeln(prefix.ansi.style(AnsiStyle.init.bold), ": ", value);
    }
    
    void entab()
    {
        g_tabCount++;
    }

    void detab(LuaState* l)
    {
        if(g_tabCount == 0)
            l.error("Cannot detab any further than 0.");
        g_tabCount--;
    }

    string execute(string command, string[] values)
    {
        const comm = escapeShellCommand(command)~" "~escapeShellCommand(values);
        printPrefixed("Executing", comm);
        auto result = executeShell(comm);
        return result.output;
    }

    string downloadTemp(string url)
    {
        printPrefixed("Downloading", url);
        download(url, "./temp");
        return "./temp";
    }

    void ensureDir(string dir)
    {
        if(!exists(dir))
            mkdirRecurse(dir);
    }

    void unzip(string zip, string dir)
    {
        // TEMP
        execute("7z", ["x", zip, "-o"~dir]);
    }

    string matchFirst(string root, string pattern)
    {
        auto r = regex(pattern);
        foreach(string entry; dirEntries(root, SpanMode.shallow))
        {
            auto result = std.regex.matchFirst(entry, r);
            if(!result.empty)
                return entry;
        }
        return null;
    }

    void unnestDir(string dir)
    {
        const root = dir.dirName;

        foreach(DirEntry entry; dirEntries(dir, SpanMode.depth))
        {
            if(entry.isDir)
                continue;

            auto newLife = entry.name[0..root.length]~entry.name[dir.length..$];
            if(!exists(newLife.dirName))
                mkdirRecurse(newLife.dirName);
            std.file.copy(entry, newLife);
        }
    }

    void cd(string dir)
    {
        chdir(dir);
    }
}

// juptune.path
private
{
    string getToolPath(string toolName)
    {
        // TEMP
        return "__tools/"~toolName~"/";
    }

    string projectPath()
    {
        // TEMP
        return thisExePath.dirName;
    }
}

// juptune.platform
private
{
    string platformName()
    {
        version(Windows)
            return "windows";
        else version(posix)
            return "posix";
        else
            return "unknown";
    }
}

// _G.hashOf
string hashLuaTable(LuaState* lua, LuaValue table)
{
    Murmur3_32 hash;

    void hashTable(int idx)
    {
        lua.push(null);
        while(lua.next(idx))
        {
            // Hash the key
            if(lua.type(-2) == LuaValue.Kind.number)
            {
                const value = lua.to!long(-2);
                hash.put((&value)[0..1]);
            }
            else
                hash.put(lua.to!(const(char)[])(-2));

            // Then the value
            switch(lua.type(-1))
            {
                case LuaValue.Kind.boolean:
                    const value = lua.to!bool(-1);
                    hash.put((&value)[0..1]);
                    break;

                case LuaValue.Kind.number:
                    const value = lua.to!LuaNumber(-1);
                    hash.put((&value)[0..1]);
                    break;

                case LuaValue.Kind.text:
                    const value = lua.to!(const(char)[])(-1);
                    hash.put(value);
                    break;

                case LuaValue.Kind.table:
                    hashTable(-2);
                    break;

                default: break;
            }

            // Pop the value
            lua.pop(1);
        }
    }

    hashTable(1);
    return hash.value.to!string(16);
}

// Conversion of the canonical source, wrapped into an incremental struct.
// Original code is public domain with copyright waived.
@nogc nothrow
struct HashMurmur3_32(uint Seed)
{
    import core.bitop : rol;
    static if(Seed == -1)
    {
        private uint _seed;
        @safe
        this(uint seed) pure
        {
            this._seed = seed;
        }
    }
    else
        private uint _seed = Seed;

    @property @safe
    uint value() pure const
    {
        return this._seed;
    }

    @trusted
    void put(const void[] key)
    {
        const data    = (cast(const(ubyte)[])key).ptr;
        const nblocks = cast(uint)(key.length / 4);

        uint h1 = this._seed;

        const uint c1 = 0xcc9e2d51;
        const uint c2 = 0x1b873593;

        if(!__ctfe)
        {
            const blocks = cast(uint*)(data + (nblocks * 4));
            for(int i = -nblocks; i; i++)
            {
                version(LittleEndian)
                    uint k1 = blocks[i];
                else
                    static assert(false, "TODO for Big endian");

                k1 *= c1;
                k1 = rol(k1, 15);
                k1 *= c2;

                h1 ^= k1;
                h1 = rol(h1, 13);
                h1 = h1*5+0xe6546b64; // ok
            }
        }
        else // CTFE can't do reinterpret casts of different byte widths.
        {
            for(int i = nblocks; i; i--)
            {
                const blockI = (i * 4);
                uint k1 = (
                    (data[blockI-4] << 24)
                  | (data[blockI-3] << 16)
                  | (data[blockI-2] << 8)
                  | (data[blockI-1] << 0)
                );

                k1 *= c1;
                k1 = rol(k1, 15);
                k1 *= c2;

                h1 ^= k1;
                h1 = rol(h1, 13);
                h1 = h1*5+0xe6546b64;
            }
        }

        const tail = (data + (nblocks * 4));

        uint k1 = 0;

        final switch(key.length & 3)
        {
            case 3: k1 ^= tail[2] << 16; goto case;
            case 2: k1 ^= tail[1] << 8; goto case;
            case 1: k1 ^= tail[0]; goto case;
            case 0: k1 *= c1;
                    k1 = rol(k1, 15);
                    k1 *= c2;
                    h1 ^= k1;
                    break;
        }

        h1 ^= key.length;
        h1 ^= h1 >> 16;
        h1 *= 0x85ebca6b;
        h1 ^= h1 >> 13;
        h1 *= 0xc2b2ae35;
        h1 ^= h1 >> 16;
        this._seed = h1;
    }
}
///
unittest
{
    const key      = "The quick brown fox jumps over the lazy dog.";
    const seed     = 0;
    const expected = 0xD5C48BFC;

    HashMurmur3_32!seed hash;
    hash.put(key);
    assert(hash.value == expected);
}

alias Murmur3_32 = HashMurmur3_32!104_729; // Constant taken from the internet somewhere.