import std, jcli;
import juptune.commands;

int main(string[] args)
{
    return (new CommandLineInterface!ALL_COMMANDS()).parseAndExecute(args);
}
