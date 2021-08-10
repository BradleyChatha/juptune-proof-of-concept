module juptune.commands.build;

import std, juptune.sdl, juptune.lua, jcli, bindbc.lua;

@Command("build")
struct BuildCommand
{
    @CommandPositionalArg(0, "file")
    string file;

    @CommandPositionalArg(1, "toolchain")
    string toolchain;

    void onExecute()
    {
        auto lua = newJuptuneLua();
        const text = translateJupfile(this.file.readText, this.file.dirName);

        const cwd = getcwd();
        chdir(this.file.dirName);
        scope(exit) chdir(cwd);
        
        lua.doString(text);
        lua.push(this.toolchain);
        lua_setglobal(lua.state, "_toolchain");
        lua.doString("juptune.toolchains.__execute(_toolchain)");
    }
}