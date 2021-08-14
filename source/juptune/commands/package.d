module juptune.commands;

import std;

public import 
    juptune.commands.debug_;

alias ALL_COMMANDS = AliasSeq!(
    DebugCommand
);