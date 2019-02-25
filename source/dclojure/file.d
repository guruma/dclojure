module dclojure.file;

import  std.string;

public import std.file: exists, isDir, isFile; 


bool isExec(string fname)
{
    bool isExist = false;

    version (Windows)
    {
        import core.sys.windows.stat;
        struct_stat st;

        isExist = (0 == stat(fname.toStringz, &st));

        if( ! isExist ) 
            return false;

        return (0 != (st.st_mode & S_IEXEC));
    }
    else version (Posix)
    {
        import core.sys.posix.sys.stat;
        stat_t st;

        isExist = (0 == stat(fname.toStringz, &st));

        if( ! isExist ) 
            return false;

        return (0 != (st.st_mode & S_IXUSR));
    }
}

unittest 
{
    assert(0 == 0);
}
