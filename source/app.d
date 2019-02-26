import std.stdio,
       std.path,
       dclojure.file,
       dclojure.util;

import std.file: mkdirRecurse;
import std.process: env = environment, executeShell;
import std.array: join;

string clojureToolsJar = "clojure-tools-1.10.0.414.jar";

void main(string[] args)
{
    normal(args);
    //test1(args);
    //test2();
    //test3();
}

void normal (string[] args)
{
    Opts opts = parseArgs(args[1 .. $]);

    string javaCmd = findJava();

    if(opts.help)
    {
        writeln(helpMessage);
    }

    version (Windows)
        string installDir = buildPath(env.get("LocalAppData"), "lib", "clojure");
    version (Posix) 
        string installDir = buildPath("/usr", "local", "lib", "clojure");
    
    string toolsCp = buildPath(installDir, "libexec", clojureToolsJar);
  

    resolveTags();


    string configDir = configDir();
    string userCacheDir = determineCacheDir(configDir);

    string[] configPaths;
    if(opts.repro)
        configPaths = [buildPath(installDir, "deps.edn"), "deps.edn"];
    else
        configPaths = [buildPath(installDir, "deps.edn"), buildPath(configDir, "deps.edn"), "deps.edn"];

    string configStr = join(configPaths, ",");

    debug writeln("configDir = ", configDir);
    debug writeln("userCacheDir = ", userCacheDir);
    debug writeln("configPaths = ", configPaths);
    debug writeln("configStr = ", configStr);


    string cacheDir;

    if(exists("deps.edn"))
        cacheDir = ".cpcache";
    else
        cacheDir = userCacheDir;

    debug writeln("cacheDir = ", cacheDir);
    debug writeln("userCacheDir = ", userCacheDir);

    string ck = makeCk();

    string libsFile = cacheDir ~ ck ~ ".libs";
    string cpFile = cacheDir ~ ck ~ ".cp";
    string jvmFile = cacheDir ~ ck ~ ".jvm";
    string mainFile = cacheDir ~ ck ~ ".main";

    if(opts.verbose) 
        printVerbose();
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


