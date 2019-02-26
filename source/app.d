import std.stdio,
       dclojure.file,
       dclojure.util;

import std.file: mkdirRecurse;


void main(string[] args)
{
   test1(args);
   test2();
   test3();
}


void test1(string[] args)
{
    string configDir;

    if("dclojure".exists) writeln("exist");
 
    runJava("/usr/bin/java -version");
    writeln("configDir = ", determineConfigDir());

    Opts opts = parseArgs(args[1 .. $]);
    writeln("opts = ", opts);

    writeln(helpMessage);
 }

void test2()
{
    auto f = "dclojure";

    writefln("exists   : %d", f.exists);
    writefln("isDir    : %d", f.isDir);
    writefln("isFile   : %d", f.isFile);
    writefln("isExec   : %d", f.isExec);
}

void test3()
{
    string s = findJava();
    writeln("JavaCmd = ", s);

    string configDir = determineConfigDir();
    writeln("configDir = ", configDir);

    if (!isDir(configDir))
        mkdirRecurse(configDir);

    string cacheDir = determineCacheDir(configDir);
    writeln("cacheDir = ", cacheDir);
}


