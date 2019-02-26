import std.stdio,
       dclojure.file,
       dclojure.util;

import std.file: mkdirRecurse;


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

    string java_cmd = findJava();

    if(opts.help)
    {
        writeln(helpMessage);
    }

    version (Windows)
    {
       string install_dir = "/usr/local/lib/clojure";
       string tools_cp = install_dir ~ "/libexec/clojure-tools-1.10.0.414.jar";
    }
    version (Posix) 
    {
        string install_dir = "/usr/local/lib/clojure";
        string tools_cp = install_dir ~ "/libexec/clojure-tools-1.10.0.414.jar";
    }

    resolveTags();

    string config_dir = configDir();

    string user_cache_dir = determineCacheDir(config_dir);

    string[] config_paths;

    if(opts.repro)
        config_paths = [install_dir ~ "/deps.edn", "deps.edn"];
    else
        config_paths = [install_dir ~ "/deps.edn", config_dir ~ "/deps.edn", "deps.edn"];

    string config_str = makeConfigStr(config_paths);

    string cache_dir;

    if(exists("deps.end"))
        cache_dir = ".cpcache";
    else
        cache_dir = user_cache_dir;

    string ck = makeCk();

    string libs_file = cache_dir ~ ck ~ ".libs";
    string cp_file = cache_dir ~ ck ~ ".cp";
    string jvm_file = cache_dir ~ ck ~ ".jvm";
    string main_file = cache_dir ~ ck ~ ".main";

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


