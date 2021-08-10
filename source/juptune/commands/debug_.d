module juptune.commands.debug_;

import std, juptune.sdl, juptune.lua, jcli, jcli : Command;

@Command("translate")
struct TranslateCommand
{
    @CommandPositionalArg(0, "file", "The file to print the AST for.")
    string file;

    void onExecute()
    {
        writeln(translateJupfile(this.file.readText, this.file.dirName));
    }
}

@Command("dump data")
struct DumpDataCommand
{
    @CommandPositionalArg(0)
    string file;

    void onExecute()
    {
        auto lua = newJuptuneLua();
        const text = translateJupfile(this.file.readText, this.file.dirName);
        lua.doString(text);
        lua.doString("print(inspect(juptune))");
    }
}