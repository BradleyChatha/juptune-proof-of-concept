tool('clang',
{
    argToShowUser = 'source',

    func = function(args)
        local source    = args:expect('source', 'string')
        local dest      = args:expect('dest', 'string')
        local flags     = args:maybe('flags', 'string_array')

        if not juptune.files.isOutOfDate(source, dest, flags) then
            return
        end

        juptune.path.ensureDir(dest)
    
        local clang   = juptune.env.CLANG_PATH or 'clang'
        local command =    clang  .. ' '
                        .. source .. ' '
                        .. '-o '  .. dest ..  ' '
        for i, flag in ipairs(flags) do
            command = command .. flag .. ' '
        end

        juptune.shell.execExpectStatus(
            command,
            0,
            'Could not compile file: '..source
        )
        juptune.files.update(source, dest, flags)
        juptune.files.update(dest)
        --juptune.files.addOutput(dest)
    end
})

tool('link',
{
    argToShowUser = 'objs',

    func = function(args)
        local objs   = args:expect('objs', 'string_array')
        local output = args:expect('output', 'string')

        juptune.path.ensureDir(output)

        local build = false
        for i, v in ipairs(objs) do
            if juptune.files.isOutOfDate(v) then 
                build = true
            end
        end

        local clang = juptune.env.CLANG_PATH or 'clang'
        local command = clang .. ' ' .. '-o ' .. output .. ' ' 
        for i, obj in ipairs(objs) do
            command = command .. obj .. ' '
        end

        juptune.shell.execExpectStatus(
            command,
            0,
            'Could not link executable'
        )

        for i, v in ipairs(objs) do
            juptune.files.update(v)
        end
        juptune.files.update(output)
        --juptune.files.addOutput(output)
    end
})

stage('build object files',
{
    func = function(args)
        local sources = args:expect('sources', 'string_array')
        local debug   = args:maybe('debug', 'boolean') or false
        local flags   = args:maybe('flags', 'string_array') or {}
        local objs    = {}

        table.insert(flags, "-c")

        for i, source in ipairs(sources) do
            local dest = 'obj/' .. juptune.path.setExt(juptune.path.fileName(source), '.o')
            table.insert(objs, dest)
            juptune.tools.clang({
                source = source,
                dest   = dest,
                flags  = juptune.alg.merge(debug and {'-G'} or {'-O3', '-Wall'}, flags)
            })
        end

        return objs
    end
})

stage('link',
{
    func = function(args)
        local objs   = args:expect('objs', 'string_array')
        local output = args:expect('output', 'string')

        juptune.tools.link({
            objs   = objs,
            output = output,
        })

        return objs
    end
})

pipeline('build c',
{
    func = function(args)
        local sources   = args:expect('sources', 'string_array')
        local output    = args:expect('output', 'string')
        local include   = args:expect('include', 'string_array')
        local flags     = args:maybe('flags', 'string_array') or {}

        for i, inc in ipairs(include) do
            table.insert(flags, '-I '..inc)
        end

        local result = juptune.stages['build object files']({
            sources = sources,
            flags   = flags
        })

        result = juptune.stages['link']({
            objs   = result,
            output = output
        })

        return output
    end
})

pipeline('run executable',
{
    func = function(args)
        local exe = args:expect('exe', 'string')

        juptune.shell.execExpectStatus(
            '"'..exe..'"',
            0,
            "Executable returned non-0"
        )
    end
})