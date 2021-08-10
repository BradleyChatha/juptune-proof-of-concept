juptune.files = juptune.files or {}

function juptune.files.isOutOfDate(path, ...)
    local metadata = {...}
    local hash = juptune.hashOfTable(metadata)
    return juptune.files.isOutOfDateImpl(path, hash)
end

function juptune.files.update(path, ...)
    local metadata = {...}
    local hash = juptune.hashOfTable(metadata)
    juptune.files.updateImpl(path, hash)
end