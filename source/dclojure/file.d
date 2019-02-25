module dclojure.file;

import std.string,
       std.traits,
       core.stdc.errno,
       std.internal.cstring,
       std.range.primitives;

static import std.file;
import std.stdio;

version (Windows)
{
    private alias FSChar = WCHAR;       // WCHAR can be aliased to wchar or wchar_t
}
else version (Posix)
{
    private alias FSChar = char;
}
else
    static assert(0);

private T cenforce(T)(T condition, lazy scope const(char)[] name, string file = __FILE__, size_t line = __LINE__)
{
    if (condition)
        return condition;
    version (Windows)
    {
        throw new std.file.FileException(name, .GetLastError(), file, line);
    }
    else version (Posix)
    {
        throw new std.file.FileException(name, .errno, file, line);
    }
}

version (Windows)
@trusted
private T cenforce(T)(T condition, scope const(char)[] name, scope const(FSChar)* namez,
    string file = __FILE__, size_t line = __LINE__)
{
    if (condition)
        return condition;
    if (!name)
    {
        import core.stdc.wchar_ : wcslen;
        import std.conv : to;

        auto len = namez ? wcslen(namez) : 0;
        name = to!string(namez[0 .. len]);
    }
    throw new std.file.FileException(name, .GetLastError(), file, line);
}

version (Posix)
@trusted
private T cenforce(T)(T condition, scope const(char)[] name, scope const(FSChar)* namez,
    string file = __FILE__, size_t line = __LINE__)
{
    if (condition)
        return condition;
    if (!name)
    {
        import core.stdc.string : strlen;

        auto len = namez ? strlen(namez) : 0;
        name = namez[0 .. len].idup;
    }
    throw new std.file.FileException(name, .errno, file, line);
}

bool isExec(string fname)
{
    bool isExist = false;

    version (Windows)
    {
        import core.sys.windows.stat;
        struct_stat st;

	auto namez = fname.tempCString!FSChar();
	static auto trustedStat(const(FSChar)* namez) @trusted
	{
	    return stat(namez, &st);
	}

        isExist = (0 == trustedStat(namez, &st));

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

private bool _isExec(R)(R name)
if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R) &&
    !isConvertibleToString!R)
{
    version (Windows)
    {
	import core.sys.windows.stat;
        auto namez = name.tempCString!FSChar();

        static auto trustedStat(const(FSChar)* namez, ref stat_t buf) @trusted
        {
	    return stat(namez, &st);
        }

	struct_stat st = void;
        immutable result = trustedStat(namez, st);

        static if (isNarrowString!R && is(Unqual!(ElementEncodingType!R) == char))
            alias names = name;
        else
            string names = null;
        cenforce(result == 0, names, namez);

        return (0 != (result & S_IEXEC));
	//return (result & S_IFMT) == S_IEXEC;
    }
    else version (Posix)
    {
	import core.sys.posix.sys.stat;
        auto namez = name.tempCString!FSChar();

        static auto trustedStat(const(FSChar)* namez, ref stat_t buf) @trusted
        {
            return stat(namez, &buf);
        }

        stat_t st = void;
        immutable result = trustedStat(namez, st);

        static if (isNarrowString!R && is(Unqual!(ElementEncodingType!R) == char))
            alias names = name;
        else
            string names = null;
        cenforce(result == 0, names, namez);

	writeln("names = ", names);
	printf("st_mode = %x\n", st.st_mode);

        return (0 != (st.st_mode & S_IXUSR));
        //return (st.st_mode & S_IFMT) == S_IXUSR;
    }
}

/*
public bool isExec(R)(R name)
if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R) &&
    !isConvertibleToString!R)
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

public bool isExec(R)(auto ref R name)
if (isConvertibleToString!R)
{
    try 
    {
	return name._isExec!(StringTypeOf!R);
    } 
    catch(Exception e)
    {
	return false;
    }
}
*/

public bool exists(R)(R name)
if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R) &&
    !isConvertibleToString!R)
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

public bool exists(R)(auto ref R name)
if (isConvertibleToString!R)
{
    try 
    {
	return std.file.exists!(StringTypeOf!R)(name);
    } 
    catch(Exception e)
    {
	return false;
    }
}

public bool isDir(R)(R name)
if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R) &&
    !isConvertibleToString!R)
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

public bool isDir(R)(auto ref R name)
if (isConvertibleToString!R)
{
    try 
    {
	return std.file.isDir!(StringTypeOf!R)(name);
    } 
    catch(Exception e)
    {
	return false;
    }
}

public bool isFile(R)(R name)
if (isInputRange!R && !isInfinite!R && isSomeChar!(ElementEncodingType!R) &&
    !isConvertibleToString!R)
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

public bool isFile(R)(auto ref R name)
if (isConvertibleToString!R)
{
    try 
    {
	return std.file.isFile!(StringTypeOf!R)(name);
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
