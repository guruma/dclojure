module dclojure.file;

import  std.stdio,
        std.range.primitives,
        std.traits;

bool exists(R)(R name)
{
    static import std.file;
    return std.file.exists(name);
}

bool isDir(R)(R name)
if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R) && !isConvertibleToString!R)
{
    static import std.file;
    return std.file.isDir(name);
}

bool isFile(R)(R name)
{
    static import std.file;
    return std.file.isFile(name);
}

bool isExec(string fname)
{
    bool isExist = false;

    version (Windows)
    {
        import core.sys.windows.stat;
        struct_stat st;

        isExist = (0 == stat(cast(char*)fname, &st));

        if( ! isExist ) 
            return false;

        return (0 != (st.st_mode & S_IEXEC));
    }
    else version (Posix)
    {
        import core.sys.posix.sys.stat;
        stat_t st;

        isExist = (0 == stat(cast(char*)fname, &st));

        if( ! isExist ) 
            return false;

        return (0 != (st.st_mode & S_IXUSR));
    }
}

unittest 
{
    assert(0 == 0);
}
