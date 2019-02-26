import std.stdio,
       dclojure.file,
       dclojure.util;

import std.file: mkdirRecurse;

Opts opts;
string configDir;
string cacheDir;

void main(string[] args)
{
   test1(args);
   test2();
   test3();
}


void test1(string[] args)
{
    if("dclojure".exists) writeln("exist");
 
    runJava("/usr/bin/java -version");
    writeln("configDir = ", determineConfigDir());

    opts = parseArgs(args[1 .. $]);
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

    configDir = determineConfigDir();
    writeln("configDir = ", configDir);

    if (!isDir(configDir))
        mkdirRecurse(configDir);

    cacheDir = determineCacheDir(configDir);
    writeln("cacheDir = ", cacheDir);
}


