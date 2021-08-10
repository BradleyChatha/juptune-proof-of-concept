module juptune.commands;

import std;

alias ALL_COMMANDS = AliasSeq!(
    juptune.commands.debug_,
    juptune.commands.build
);

public import
    juptune.commands.debug_,
    juptune.commands.build;