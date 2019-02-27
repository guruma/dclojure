import std.stdio,
       std.string,
       std.path,
       std.array,
       dclojure.file,
       dclojure.util;

import std.process: env = environment, executeShell;


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
    Vars vars;
    resolveTags(vars);
}

void testMakeChecksum()
{
    string[] a = ["a", "b", "c"];
    string[] b = ["1", "2", "3"];
    string[] paths = ["dclojur", "dub.json"];

    Opts opts;
    Vars vars;

    string ck = makeChecksum(vars, opts);

    writeln(ck);
}

void normal (string[] args)
{
    writeln("normal test");

    Vars vars;
    vars.toolsVersion = "1.10.0.414";
    vars.toolsJar = "clojure-tools-" ~ vars.toolsVersion ~ ".jar";

    Opts opts = parseArgs(args[1 .. $]);

    vars.javaCmd = findJava();

    if(opts.help)
    {
        writeln(helpMessage);
    }

    version (Windows)
        vars.installDir = buildPath(env.get("LocalAppData"), "lib", "clojure");
    version (linux) 
        vars.installDir = "/usr/local/lib/clojure";
    version (OSX) 
        vars.installDir = "/usr/local/Cellar/clojure/" ~ vars.toolsVersion;
    
    vars.toolsCp = buildPath(vars.installDir, "libexec", vars.toolsJar);
  
    if (opts.resolveTags)
        resolveTags(vars);

    vars.configDir = determineConfigDir();
    vars.userCacheDir = determineCacheDir(vars.configDir);

    if (opts.repro)
        vars.configPaths = [buildPath(vars.installDir, "deps.edn"), "deps.edn"];
    else
        vars.configPaths = [buildPath(vars.installDir, "deps.edn"), 
                            buildPath(vars.configDir, "deps.edn"), "deps.edn"];

    vars.configStr = join(vars.configPaths, ",");

    debug writeln("configDir = ", vars.configDir);
    debug writeln("userCacheDir = ", vars.userCacheDir);
    debug writeln("configPaths = ", vars.configPaths);
    debug writeln("configStr = ", vars.configStr);

    if(exists("deps.edn"))
        vars.cacheDir = ".cpcache";
    else
        vars.cacheDir = vars.userCacheDir;

    debug writeln("cacheDir = ", vars.cacheDir);
    debug writeln("userCacheDir = ", vars.userCacheDir);

    vars.ck = makeChecksum(vars, opts);

    vars.libsFile = buildPath(vars.cacheDir, vars.ck ~ ".libs");
    vars.cpFile   = buildPath(vars.cacheDir, vars.ck ~ ".cp");
    vars.jvmFile  = buildPath(vars.cacheDir, vars.ck ~ ".jvm");
    vars.mainFile = buildPath(vars.cacheDir, vars.ck ~ ".main");

    debug writeln("libsFile = ", vars.libsFile);

    if (opts.verbose)
        printVerbose(vars);

    if (opts.describe)
        printDescribe(vars, opts);

    if(opts.force || !vars.cpFile.exists)
        vars.stale = true;
    else
    {
        foreach(configPath; vars.configPaths)
        {
            if(newerThan(configPath, vars.cpFile))
            {
                vars.stale = true;
                break;
            }
        }
    }

    if (vars.stale || opts.pom)
        vars.toolsArgs = makeToolsArgs(vars, opts);
    
    if (vars.stale && ! opts.describe)
    {
        if(opts.verbose)
            writeln("Refreshing classpath");
        makeClasspath(vars, opts);
    }

    if(opts.describe)
        vars.cp = "";
    else if(! opts.forceCp.empty())
        vars.cp = opts.forceCp;
    else
        vars.cp = readText(vars.cpFile);

    if(opts.pom)
        generateManifest(vars, opts);
    else if(opts.printClasspath)
        writeln(vars.cp);
    else if(opts.describe)
        printDescribe(vars, opts);
    else if(opts.tree)
        printTree(vars, opts);
    else
    {
        if(vars.jvmFile.exists)
            vars.jvmCacheOpts = readText(vars.jvmFile);

        if(vars.mainFile.exists)
            vars.mainCacheOpts = readText(vars.mainFile);

        runClojure(vars, opts);
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
    import std.file: mkdirRecurse;
    string s = findJava();
    writeln("JavaCmd = ", s);

    string configDir = determineConfigDir();
    writeln("configDir = ", configDir);

    if (!isDir(configDir))
        mkdirRecurse(configDir);

    string cacheDir = determineCacheDir(configDir);
    writeln("cacheDir = ", cacheDir);
}
