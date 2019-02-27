module dclojure.file;

import std.string,
       std.traits,
       std.stdio,
       core.stdc.errno,
       core.stdc.string,
       std.internal.cstring,
       std.range.primitives;

static import std.file;


private bool _isExec(string name)
{
    version (Windows)
    {
        import core.sys.windows.stat;

        static auto trustedStat(const(char)* namez, ref struct_stat st) @trusted
        {
            return stat(namez, &st);
        }

        struct_stat st = void;
        immutable result = trustedStat(name.toStringz(), st);

        return (0 != (result & S_IEXEC));
        //return (result & S_IFMT) == S_IEXEC;
    }
    else version (Posix)
    {
        import core.sys.posix.sys.stat;

        int trustedStat(const(char)* namez, ref stat_t st) @trusted
        {
            return stat(namez, &st);
        }

        stat_t st = void;

        immutable result = trustedStat(name.toStringz(), st);

        return (0 != (st.st_mode & S_IXUSR));
        //return (st.st_mode & S_IFMT) == S_IXUSR;
    }
}

public bool isExec(string name)
{
    try 
    {
        return _isExec(name);
    } 
    catch(Exception e)
    {
        return false;
    }
}

public bool exists(string name)
{
    try 
    {
        return std.file.exists(name);
    } 
    catch(Exception e)
    {
        return false;
    }
}

public bool isDir(string name)
{
    try 
    {
        return std.file.isDir(name);
    } 
    catch(Exception e)
    {
        return false;
    }
}

public bool isFile(string name)
{
    try 
    {
        return std.file.isFile(name);
    } 
    catch(Exception e)
    {
        return false;
    }
}

unittest 
{
    assert(0 == 0);
}
