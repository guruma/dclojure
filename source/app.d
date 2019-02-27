import std.stdio,
       std.string,
       dclojure.file,
       dclojure.util;

import std.file: mkdirRecurse;
import std.process: env = environment, executeShell;
import std.path: buildPath;
import std.array: join;

enum toolsVersion = "1.10.0.414";
string toolsJar = "clojure-tools-" ~ toolsVersion ~ ".jar";

void main(string[] args)
{
    normal(args);
    //test1(args);
    //test2();
    //test3();
    //testMakeChecksum();
    //testResolveTags();
}

void testResolveTags()
{
    resolveTags("/usr/bin/java", "");
}

void testMakeChecksum()
{
    string[] a = ["a", "b", "c"];
    string[] b = ["1", "2", "3"];
    string[] paths = ["dclojur", "dub.json"];

    string ck = makeChecksum(a,a,a,a,b,"deps.data", paths);

    writeln(ck);
}

void normal (string[] args)
{
    writeln("normal test");

    Opts opts = parseArgs(args[1 .. $]);

    string javaCmd = findJava();

    if(opts.help)
    {
        writeln(helpMessage);
    }

    version (Windows)
        string installDir = buildPath(env.get("LocalAppData"), "lib", "clojure");
    version (linux) 
        string installDir = "/usr/local/lib/clojure";
    version (OSX) 
        string installDir = "/usr/local/Cellar/clojure/1.10.0.414";
    
    string toolsCp = buildPath(installDir, "libexec", toolsJar);
  
    if(opts.resolveTags)
        resolveTags(javaCmd, toolsCp);

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

    string ck = makeChecksum(
                    opts.resolveAliases,
                    opts.classpathAliases,
                    opts.allAliases,
                    opts.jvmAliases,
                    opts.mainAliases,
                    opts.depsData,
                    configPaths);

    string libsFile = buildPath(cacheDir, ck ~ ".libs");
    string cpFile = buildPath(cacheDir, ck ~ ".cp");
    string jvmFile = buildPath(cacheDir, ck ~ ".jvm");
    string mainFile = buildPath(cacheDir, ck ~ ".main");

    debug writeln("libsFile = ", libsFile);

    if (opts.verbose)
        printVerbose(toolsVersion, installDir, configDir, configPaths, cacheDir, cpFile);

    if (opts.describe)
        printDescribe(toolsVersion, configPaths, installDir, configDir, cacheDir, opts);

    bool stale = false;

    if(opts.force || !cpFile.exists)
    { 
        stale = true;
    }
    else
    {
        foreach(configPath; configPaths)
        {
            if(newerThan(configPath, cpFile))
            {
                stale = true;
                break;
            }

        }
    }

    string[] toolsArgs;

    if(stale || opts.pom)
    {
        toolsArgs = makeToolsArgs();
    }
    
    if(stale && ! opts.describe)
    {
        if(opts.verbose)
            writeln("Refreshing classpath");
        //runJava
    }

    string cp;

    if(opts.describe)
        cp = "";
    else if(! opts.forceCp.empty())
        cp = opts.forceCp;
    else
        cp = readText(cpFile);

    if(opts.pom)
    {
        //runJava
    }
    else if(opts.printClasspath)
    {
        writeln(cp);
    }
    else if(opts.describe)
    {
        //printDescribe();
    }
    else if(opts.tree)
    {
        //runJava
    }
    else
    {
        string jvmCacheOpts, mainCacheOpts;

        if(jvmFile.exists)
            jvmCacheOpts = readText(jvmFile);

        if(mainFile.exists)
            mainCacheOpts = readText(mainFile);

        //runJava
    }
    
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
