module juptune.sdl.translate;

import std, sdlite, juptune.sdl, juptune.lua;

string translateJupfile(string contents, string dir)
{
    SDLNode[] defines;
    SDLNode[] uses;
    SDLNode[] toolchains;

    parseSDLDocument!((n)
    {
        if(n.namespace == "define")
            defines ~= n;
        else if(n.name == "use")
            uses ~= n;
        else if(n.name == "toolchain")
            toolchains ~= n;
        else
            throw new Exception("Unexpected node on top-level called: "~n.qualifiedName);
    })(contents, "jupfile");

    Appender!(char[]) output;

    foreach(define; defines)
    {
        output.put("local ");
        output.put(define.name);
        output.put(" = ");
        translateValuesToLuaValue(define.values, output);
        output.put('\n');
    }

    foreach(use; uses)
    {
        output.put("dofile('");
        output.put(dir.buildPath(use.values[0].textValue).absolutePath.buildNormalizedPath.substitute('\\', '/'));
        output.put("')");
        output.put('\n');
    }

    foreach(toolchain; toolchains)
    {
        SDLNode[] pipelines;

        output.put("toolchain('");
        output.put(toolchain.values[0].textValue);
        output.put("', {");

        foreach(child; toolchain.children)
        {
            if(child.name == "pipeline")
                pipelines ~= child;
            else
                throw new Exception("Unexpected node inside toolchain node: "~child.qualifiedName);
        }

        output.put("\n\tpipelines = {\n");
        foreach(pipeline; pipelines)
        {
            SDLNode[] exports;

            output.put("\t\t{ ");
            output.put("__pipeline = '"); output.put(pipeline.values[0].textValue); output.put("', ");
            foreach(i, n; pipeline.children)
            {
                if(n.namespace == "export")
                {
                    exports ~= n;
                    continue;
                }

                output.put(n.name);
                output.put(" = ");
                if(n.namespace == "bind")
                {
                    const value = n.getAttribute("to").textValue;
                    if(value.canFind(":"))
                    {
                        output.put("function() return juptune.core.getPipelineReturnVar('");
                        output.put(value);
                        output.put("') end");
                    }
                    else
                        output.put(value);
                }
                else if(n.namespace == "set")
                    translateValuesToLuaValue(n.values, output);
                else
                    throw new Exception("Unexpected node inside pipeline node: "~n.qualifiedName);

                if(i+1 < pipeline.children.length)
                    output.put(", ");
            }
            output.put(" },\n");
            
            foreach(exp; exports)
            {
                output.put("\t\t{ ");
                output.put("__export = '");
                output.put(exp.name);
                output.put("', to = '");
                output.put(exp.getAttribute("to").textValue);
                output.put("'");
                output.put(" },\n");
            }
        }
        output.put("\t}\n");
        output.put("})\n");
    }

    return output.data.assumeUnique;
}

private void translateValuesToLuaValue(SDLValue[] values, ref Appender!(char[]) output)
{
    if(values.length > 1)
        output.put('{');

    foreach(i, value; values)
    {
        final switch(value.kind) with(SDLValue.Kind)
        {
            case null_: output.put("nil"); break;
            case text: output.put('"'); output.put(value.textValue); output.put('"'); break;
            case int_: output.put(value.intValue.to!string); break;
            case long_: output.put(value.longValue.to!string); break;
            case float_: output.put(value.floatValue.to!string); break;
            case double_: output.put(value.doubleValue.to!string); break;
            case bool_: output.put(value.boolValue.to!string); break;
            
            case date:
            case duration:
            case dateTime:
            case decimal:
            case binary: throw new Exception("Unsupported value type: "~value.kind.to!string);
        }

        if(i+1 < values.length)
            output.put(", ");
    }

    if(values.length > 1)
        output.put('}');
}