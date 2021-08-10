import std, jcli;
import juptune.commands, juptune.lua;

int main(string[] args)
{
    return (new CommandLineInterface!ALL_COMMANDS()).parseAndExecute(args);
}
